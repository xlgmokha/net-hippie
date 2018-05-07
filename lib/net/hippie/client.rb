module Net
  module Hippie
    class Client
      DEFAULT_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "net/hippie #{Net::Hippie::VERSION}",
      }

      def initialize(
        certificate: nil,
        key: nil,
        passphrase: nil,
        mapper: JsonMapper.new
      )
        @certificate = certificate
        @default_headers = DEFAULT_HEADERS
        @key = key
        @mapper = mapper
      end

      def execute(uri, request)
        http_for(uri).request(request)
      end

      def get(uri, headers: {}, body: {})
        request = request_for(Net::HTTP::Get, uri, headers: headers, body: body)
        response = execute(uri, request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      def post(uri, headers: {}, body: {})
        request = request_for(Net::HTTP::Post, uri, headers: headers, body: body)
        response = execute(uri, request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      def put(uri, headers: {}, body: {})
        request = request_for(Net::HTTP::Put, uri, headers: headers, body: body)
        response = execute(uri, request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      private

      attr_reader :default_headers
      attr_reader :certificate, :key, :passphrase
      attr_reader :mapper

      def http_for(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 30
        http.use_ssl = uri.is_a?(URI::HTTPS)
        http.set_debug_output(Net::Hippie.logger)
        http.cert = OpenSSL::X509::Certificate.new(certificate) if certificate
        if key
          if passphrase
            http.key = OpenSSL::PKey::RSA.new(key, passphrase)
          else
            http.key = OpenSSL::PKey::RSA.new(key)
          end
        end
        http
      end

      def request_for(type, uri, headers: {}, body: {})
        type.new(uri, default_headers.merge(headers)).tap do |x|
          x.body = mapper.map_from(body) unless body.empty?
        end
      end
    end
  end
end
