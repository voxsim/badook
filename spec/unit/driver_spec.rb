require 'spec_helper'

module Capybara::Badook
  describe Driver do
    let(:default_phantomjs_options) { %w[--ignore-ssl-errors=yes --wd --ssl-protocol=TLSv1] }

    context 'with no options' do
      subject { Driver.new(nil) }

      it 'does not log' do
        expect(subject.logger).to be_nil
      end

      it 'adds default phantomjs options to driver options' do
        expect(subject.phantomjs.phantomjs_options).to eq(default_phantomjs_options)
      end

      it 'has phantomjs windows_size setted to [1024, 768]' do
        expect(subject.phantomjs.window_size).to eq([1024, 768])
      end
    end

    context 'with a phantomjs_options option' do
      subject { Driver.new(nil, phantomjs_options: %w{--hello}) }

      it 'is a combination of ssl settings and the provided options' do
        expect(subject.phantomjs.phantomjs_options).to eq(%w{--hello --ignore-ssl-errors=yes --wd --ssl-protocol=TLSv1})
      end
    end

    context 'with phantomjs_options containing ssl-protocol settings' do
      subject { Driver.new(nil, phantomjs_options: %w{--ssl-protocol=any --ignore-ssl-errors=no})}

      it 'uses the provided ssl-protocol' do
        expect(subject.phantomjs.phantomjs_options).to include('--ssl-protocol=any')
        expect(subject.phantomjs.phantomjs_options).not_to include('--ssl-protocol=TLSv1')
      end

      it 'uses the provided ssl-errors' do
        expect(subject.phantomjs.phantomjs_options).to include('--ignore-ssl-errors=no')
        expect(subject.phantomjs.phantomjs_options).not_to include('--ignore-ssl-errors=yes')
      end
    end

    context 'with a :phantomjs_logger option' do
      subject { Driver.new(nil, phantomjs_logger: :my_custom_logger) }

      it 'logs to the phantomjs_logger given' do
        expect(subject.phantomjs.logger).to eq(:my_custom_logger)
      end
    end

    xcontext 'with a :logger option' do
      subject { Driver.new(nil, logger: :my_custom_logger) }

      it 'logs to the logger given' do
        expect(subject.logger).to eq(:my_custom_logger)
      end
    end

    xcontext 'with a :debug option' do
      subject { Driver.new(nil, debug: true) }

      it 'logs to STDERR' do
        expect(subject.logger).to eq(STDERR)
      end
    end

    xcontext 'with an :inspector option' do
      subject { Driver.new(nil, inspector: 'foo') }

      it 'has an inspector' do
        expect(subject.inspector).to_not be_nil
        expect(subject.inspector).to be_a(Inspector)
        expect(subject.inspector.browser).to eq('foo')
      end

      it 'can pause indefinitely' do
        expect do
          Timeout::timeout(3) do
            subject.pause
          end
        end.to raise_error(Timeout::Error)
      end

      it 'can pause and resume with keyboard input' do
        IO.pipe do |read_io, write_io|
          stub_const('STDIN', read_io)
          write_io.write "\n"

          begin
            Timeout::timeout(3) do
              subject.pause
            end
          ensure
            write_io.close # without manual close JRuby 9.1.7.0 hangs here
          end
        end
      end

      it 'can pause and resume with signal' do
        Thread.new { sleep(2); Process.kill('CONT', Process.pid); }
        Timeout::timeout(4) do
          subject.pause
        end
      end

    end

    xcontext 'with a :timeout option' do
      subject { Driver.new(nil, timeout: 3) }

      it 'starts the server with the provided timeout' do
      end
    end

    xcontext 'with a :window_size option' do
      subject { Driver.new(nil, window_size: [800, 600]) }

      it 'creates a client with the desired width and height settings' do
      end
    end
  end
end
