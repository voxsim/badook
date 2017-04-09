require 'timeout'
require 'cliver'

module Capybara::Badook
  class PhantomJS
    PHANTOMJS_NAME = 'phantomjs'
    KILL_TIMEOUT = 2 # seconds

    def self.start(*args)
      phantomjs = new(*args)
      phantomjs.start
      phantomjs
    end

    # Returns a proc, that when called will attempt to kill the given process.
    # This is because implementing ObjectSpace.define_finalizer is tricky.
    # Hat-Tip to @mperham for describing in detail:
    # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def self.process_killer(pid)
      proc do
        begin
          if Capybara::Badook.windows?
            Process.kill('KILL', pid)
          else
            Process.kill('TERM', pid)
            begin
              Timeout.timeout(KILL_TIMEOUT) { Process.wait(pid) }
            rescue Timeout::Error
              Process.kill('KILL', pid)
              Process.wait(pid)
            end
          end
        rescue Errno::ESRCH, Errno::ECHILD
          # Zed's dead, baby
        end
      end
    end

    attr_reader :pid, :path, :window_size, :phantomjs_options, :inspector

    def initialize(options = {})
      @path              = Cliver::detect((options[:path] || PHANTOMJS_NAME), *['>=2.1.0', '< 3.0'])
      @path            ||= Cliver::detect!((options[:path] || PHANTOMJS_NAME), *['>= 1.8.1', '< 3.0']).tap do
        warn 'You\'re running an old version of PhantomJS, update to >= 2.1.1 for a better experience.'
      end

      @inspector = options[:inspector] && Inspector.new(options[:inspector])

      @window_size       = options[:window_size] || [1024, 768]
      @phantomjs_options = set_phantomjs_options(options[:phantomjs_options])
      @phantomjs_logger  = options[:phantomjs_logger] || $stdout
    end

    def start
      @read_io, @write_io = IO.pipe
      @out_thread = Thread.new {
        while !@read_io.eof? && data = @read_io.readpartial(1024)
          @phantomjs_logger.write(data)
        end
      }

      process_options = {}
      process_options[:pgroup] = true unless Capybara::Badook.windows?
      process_options[:out] = @write_io if Capybara::Badook.mri?

      redirect_stdout do
        @pid = Process.spawn(*command.map(&:to_s), process_options)
        sleep 1 # wait for phantomjs to startup properly
      end

      ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))
    end

    # TODO make this parametric
    def base_url
      'http://localhost:8910'
    end

    def stop
      if pid
        kill_phantomjs
        @out_thread.kill
        close_io
        ObjectSpace.undefine_finalizer(self)
      end
    end

    def restart
      stop
      start
    end

    def command
      parts = [path]
      parts.concat phantomjs_options
      parts.concat window_size
      parts
    end

    def phantomjs_options
      @phantomjs_options
    end

    def logger
      @phantomjs_logger
    end

    def window_size
      @window_size
    end

    def inspector
      @inspector
    end

    private

    # This abomination is because JRuby doesn't support the :out option of
    # Process.spawn. To be honest it works pretty bad with pipes too, because
    # we ought close writing end in parent process immediately but JRuby will
    # lose all the output from child. Process.popen can be used here and seems
    # it works with JRuby but I've experienced strange mistakes on Rubinius.
    def redirect_stdout
      if Capybara::Badook.mri?
        yield
      else
        begin
          prev = STDOUT.dup
          $stdout = @write_io
          STDOUT.reopen(@write_io)
          yield
        ensure
          STDOUT.reopen(prev)
          $stdout = STDOUT
          prev.close
        end
      end
    end

    def kill_phantomjs
      self.class.process_killer(pid).call
      @pid = nil
    end

    # We grab all the output from PhantomJS like console.log in another thread
    # and when PhantomJS crashes we try to restart it. In order to do it we stop
    # server and client and on JRuby see this error `IOError: Stream closed`.
    # It happens because JRuby tries to close pipe and it is blocked on `eof?`
    # or `readpartial` call. The error is raised in the related thread and it's
    # not actually main thread but the thread that listens to the output. That's
    # why if you put some debug code after `rescue IOError` it won't be shown.
    # In fact the main thread will continue working after the error even if we
    # don't use `rescue`. The first attempt to fix it was a try not to block on
    # IO, but looks like similar issue appers after JRuby upgrade. Perhaps the
    # only way to fix it is catching the exception what this method overall does.
    def close_io
      [@write_io, @read_io].each do |io|
        begin
          io.close unless io.closed?
        rescue IOError
          raise unless RUBY_ENGINE == 'jruby'
        end
      end
    end

    def set_phantomjs_options(phantomjs_options)
      list = phantomjs_options || []

      # PhantomJS defaults to only using SSLv3, which since POODLE (Oct 2014)
      # many sites have dropped from their supported protocols (eg PayPal,
      # Braintree).
      list += ['--ignore-ssl-errors=yes'] unless list.grep(/ignore-ssl-errors/).any?
      list += ['--wd']
      list += ['--ssl-protocol=TLSv1'] unless list.grep(/ssl-protocol/).any?
      list += ["--remote-debugger-port=#{inspector.port}", '--remote-debugger-autorun=yes'] if inspector
      list
    end
  end
end
