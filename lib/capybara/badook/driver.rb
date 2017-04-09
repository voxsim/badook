require 'json'
require 'base64'

module Capybara
  module Badook
    class Driver < Capybara::Driver::Base
      attr_reader :app, :options, :phantomjs, :session_id, :last_response

      def initialize(app, options = {})
        @app       = app
        @options   = options
        @phantomjs = nil
        @session_id = nil
        @last_response = nil
      end

      # Begin: implementation of Capybara::Driver::Base

      def current_url
        get("/session/#{session_id}/url").value
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
        get("/session/#{session_id}/source").value
      end

      def go_back
        post "/session/#{session_id}/back"
      end

      def go_forward
        post "/session/#{session_id}/forward"
      end

      # TODO: make this async?
      def execute_script(script, *args)
        params = JSON.generate(script: script, args: args)
        post "/session/#{session_id}/execute/sync", params
      end

      def evaluate_script(script, *args)
        params = JSON.generate(script: script, args: args)
        post "/session/#{session_id}/execute/sync", params
      end

      def save_screenshot(path, _ = {})
        response = get "/session/#{session_id}/screenshot"
        File.open(path, 'wb') do |f|
          f.write(Base64.decode64(response.value))
        end
      end

      def response_headers
        @last_response.headers
      end

      def status_code
        @last_response.code
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

      def phantomjs
        @phantomjs ||= PhantomJS.start(
          path: options[:phantomjs],
          window_size: options[:window_size],
          phantomjs_options: options[:phantomjs_options],
          phantomjs_logger: options[:phantomjs_logger],
          inspector: options[:inspector]
        )
      end

      # logger should be an object that responds to puts, or nil
      def logger
        options[:logger] || (options[:debug] && STDERR)
      end

      def session_id
        @session_id ||= generate_session
      end

      private

      def generate_session
        params = JSON.generate(desiredCapabilities: {})
        response = post '/session', params
        response.session_id
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
        response.value.map do |node|
          Capybara::Badook::Node.new(self, session_id, node['ELEMENT'])
        end
      end

      def http_client
        @http_client ||= Capybara::Badook::HttpClient.new(phantomjs.base_url)
      end

      def get(*args)
        @last_response = http_client.get(*args)
      end

      def post(*args)
        @last_response = http_client.post(*args)
      end

      def delete(*args)
        @last_response = http_client.delete(*args)
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
    end
  end
end
