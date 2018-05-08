module Net
  module Hippie
    class Api
      attr_reader :uri, :verify_mode

      def initialize(url, verify_none: false)
        @uri = URI.parse(url)
        @verify_mode = OpenSSL::SSL::VERIFY_NONE if verify_none
      end

      def get
        client.get(uri).body
      end

      def execute(request)
        client.execute(uri, request)
      end

      private

      def client
        @client ||= Client.new(headers: {}, verify_mode: verify_mode)
      end
    end
  end
end
