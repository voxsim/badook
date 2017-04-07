require 'uri'
require 'json'
require 'rest-client'
require 'base64'

module Capybara::Badook
  class Driver < Capybara::Driver::Base
    DEFAULT_TIMEOUT = 30

    attr_reader :app, :options

    def initialize(app, options = {})
      @app       = app
      @options   = options
      @inspector = nil
      @phantomjs = nil
      @session_id = nil
      @status_code = nil
      @response_headers = nil
    end

    # Begin: implementation of Capybara::Driver::Base

    def current_url
      response = get "/session/#{session_id}/url"
      response['value']
    end

    def visit(url)
      post "/session/#{session_id}/url", JSON.generate(url: url)
    end

    def find_xpath(selector)
      find 'xpath', selector
    end

    def find_css(selector)
      find 'css selector', selector
    end

    def html
      response = get "/session/#{session_id}/source"
      response['value']
    end

    def go_back
      response = post "/session/#{session_id}/back"
      response['value']
    end

    def go_forward
      response = post "/session/#{session_id}/forward"
      response['value']
    end

    # TODO make this async?
    def execute_script(script, *args)
      params = JSON.generate(script: script, args: args)
      post "/session/#{session_id}/execute/sync"
    end

    def evaluate_script(script, *args)
      params = JSON.generate(script: script, args: args)
      post "/session/#{session_id}/execute/sync"
    end

    # TODO save base64 img in path
    def save_screenshot(path, _={})
      response = get "/session/#{session_id}/screenshot"
      File.open(path, 'wb') do |f|
        f.write(Base64.decode64(response['value']))
      end
    end

    def response_headers
      @response_headers
    end

    def status_code
      @status_code
    end

    # def switch_to_frame(locator)
    #   browser.switch_to_frame(locator)
    # end

    # def current_window_handle
    #   browser.window_handle
    # end

    # def window_size(handle)
    #   within_window(handle) do
    #     evaluate_script('[window.innerWidth, window.innerHeight]')
    #   end
    # end

    # def resize_window_to(handle, width, height)
    #   within_window(handle) do
    #     resize(width, height)
    #   end
    # end

    # def maximize_window(handle)
    #   resize_window_to(handle, *screen_size)
    # end

    # def close_window(handle)
    #   browser.close_window(handle)
    # end

    # def window_handles
    #   browser.window_handles
    # end

    # def open_new_window
    #   browser.open_new_window
    # end

    # def switch_to_window(handle)
    #   browser.switch_to_window(handle)
    # end

    # def within_window(name)
    #   browser.within_window(name)
    # end

    # def no_such_window_error
    #   NoSuchWindowError
    # end

    # def accept_modal(type, options = {})
    #   case type
    #   when :confirm
    #     browser.accept_confirm
    #   when :prompt
    #     browser.accept_prompt options[:with]
    #   end

    #   yield if block_given?

    #   find_modal(options)
    # end

    # def dismiss_modal(type, options = {})
    #   case type
    #   when :confirm
    #     browser.dismiss_confirm
    #   when :prompt
    #     browser.dismiss_prompt
    #   end

    #   yield if block_given?
    #   find_modal(options)
    # end

    def invalid_element_errors
      []
    end

    def wait?
      true
    end

    def reset!
      delete_all_cookie
      delete_session
      @session_id = nil
    end

    def needs_server?
      true
    end

    # End: implementation of Capybara::Driver::Base

    def inspector
      @inspector ||= options[:inspector] && Inspector.new(options[:inspector])
    end

    def phantomjs
      @phantomjs ||= PhantomJS.start(
        path: options[:phantomjs],
        window_size: options[:window_size],
        phantomjs_options: phantomjs_options,
        phantomjs_logger: phantomjs_logger
      )
    end

    def phantomjs_options
      list = options[:phantomjs_options] || []

      # PhantomJS defaults to only using SSLv3, which since POODLE (Oct 2014)
      # many sites have dropped from their supported protocols (eg PayPal,
      # Braintree).
      list += ['--ignore-ssl-errors=yes'] unless list.grep(/ignore-ssl-errors/).any?
      list += ['--wd']
      list += ['--ssl-protocol=TLSv1'] unless list.grep(/ssl-protocol/).any?
      list += ["--remote-debugger-port=#{inspector.port}", '--remote-debugger-autorun=yes'] if inspector
      list
    end

    # logger should be an object that responds to puts, or nil
    def logger
      options[:logger] || (options[:debug] && STDERR)
    end

    # logger should be an object that behaves like IO or nil
    def phantomjs_logger
      options.fetch(:phantomjs_logger, nil)
    end

    private

    def session_id
      @session_id ||= generate_session
    end

    def generate_session
      params = JSON.generate(desiredCapabilities: {})
      response = post '/session', params
      response['sessionId']
    end

    def delete_all_cookie
      delete "/session/#{session_id}/cookie"
    end

    def delete_session
      delete "/session/#{session_id}"
    end

    def find(type, selector)
      params = JSON.generate(using: type, value: selector)
      response = post "/session/#{session_id}/elements", params
      response['value'].map { |node|
        Capybara::Badook::Node.new(self, session_id, node['ELEMENT'])
      }
    end

    def screen_size
      options[:screen_size] || [1366, 768]
    end

    def find_modal(options)
      start_time = Time.now
      timeout_sec = options[:wait] || begin Capybara.default_max_wait_time rescue Capybara.default_wait_time end
      expect_text = options[:text]
      expect_regexp = expect_text.is_a?(Regexp) ? expect_text : Regexp.escape(expect_text.to_s)
      not_found_msg = 'Unable to find modal dialog'
      not_found_msg += " with #{expect_text}" if expect_text

      begin
        modal_text = browser.modal_message
        raise Capybara::ModalNotFound if modal_text.nil? || (expect_text && !modal_text.match(expect_regexp))
      rescue Capybara::ModalNotFound => e
        raise e, not_found_msg if (Time.now - start_time) >= timeout_sec
        sleep(0.05)
        retry
      end
      modal_text
    end

    def get(url, headers = {})
      request(:get, url, headers: headers)
    end

    def post(url, body = nil, headers = {})
      request(:post, url, body: body, headers: headers)
    end

    def delete(url, headers = {})
      request(:delete, url, headers: headers)
    end

    def request(method, url, options)
      begin
        body = options[:body]
        headers = { content_type: :json }.merge(options[:headers])

        http_response = RestClient::Request.execute(
          method: method,
          url: "#{phantomjs.base_url}#{url}",
          payload: body,
          headers: headers
        )
        @status_code = http_response.code
        @response_headers = http_response.headers
        JSON.parse(http_response)
      rescue RestClient::ExceptionWithResponse => error
        if [301, 302, 307].include? error.response.code
          error.response
          Response.from(error.response)
        else
          error
          # raise Error.new(error)
        end
      rescue RestClient::Exception => error
        error
        # raise Error.new(error)
      end
    end
  end
end
