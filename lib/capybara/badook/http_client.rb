require 'rest-client'

module Capybara
  module Badook
    class HttpClient < Capybara::Driver::Base
      def initialize(base_url)
        @base_url = base_url
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
            url: "#{@base_url}#{url}",
            payload: body,
            headers: headers
          )
          Response.new(http_response)
        rescue RestClient::ExceptionWithResponse => error
          if [301, 302, 307].include? error.response.code
            Response.new(error.response)
          else
            raise Error.new(error)
          end
        rescue RestClient::Exception => error
          raise Error.new(error)
        end
      end
    end
  end
end
