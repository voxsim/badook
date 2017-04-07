require 'json'

module Capybara
  module Badook
    class Response
      # TODO should we raise here for a ghost driver error?
      def initialize(http_response)
        @http_response = http_response
        @json_response = JSON.parse(http_response)
      end

      def headers
        @http_response.headers
      end

      def code
        @http_response.code
      end

      def session_id
        @json_response['sessionId']
      end

      def value
        @json_response['value']
      end
    end
  end
end
