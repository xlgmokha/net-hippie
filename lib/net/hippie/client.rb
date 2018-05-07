module Net
  module Hippie
    class Client
      DEFAULT_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "net/hippie #{Net::Hippie::VERSION}",
      }

      def initialize(headers: DEFAULT_HEADERS, certificate: nil, key: nil)
        @certificate = certificate
        @default_headers = headers
        @key = key
      end

      def get(uri, headers: {}, body: {})
        request = get_for(uri, headers: headers, body: body)
        response = http_for(uri).request(request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      def post(uri, headers: {}, body: {})
        request = post_for(uri, headers: headers, body: body)
        response = http_for(uri).request(request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      def put(uri, headers: {}, body: {})
        request = put_for(uri, headers: headers, body: body)
        response = http_for(uri).request(request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      private

      attr_reader :default_headers, :certificate, :key

      def http_for(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 30
        http.use_ssl = true
        http.set_debug_output(Net::Hippie.logger)
        http.cert = OpenSSL::X509::Certificate.new(certificate) if certificate
        http.key = OpenSSL::PKey::RSA.new(key) if key
        http
      end

      def post_for(uri, headers: {}, body: {})
        headers = default_headers.merge(headers)
        Net::HTTP::Post.new(uri, headers).tap do |post|
          post.body = JSON.generate(body)
        end
      end

      def put_for(uri, headers: {}, body: {})
        headers = default_headers.merge(headers)
        Net::HTTP::Put.new(uri, headers).tap do |put|
          put.body = JSON.generate(body)
        end
      end

      def get_for(uri, headers: {}, body: {})
        headers = default_headers.merge(headers)
        Net::HTTP::Get.new(uri, headers).tap do |get|
          get.body = JSON.generate(body) unless body.empty?
        end
      end
    end
  end
end
