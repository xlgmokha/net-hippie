# frozen_string_literal: true

module Net
  module Hippie
    # A simple client for connecting with http resources.
    class Client
      DEFAULT_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "net/hippie #{Net::Hippie::VERSION}"
      }.freeze

      attr_accessor :mapper
      attr_accessor :read_timeout
      attr_accessor :logger

      def initialize(
        certificate: nil,
        headers: DEFAULT_HEADERS,
        key: nil,
        passphrase: nil,
        verify_mode: nil
      )
        @certificate = certificate
        @default_headers = headers
        @key = key
        @mapper = ContentTypeMapper.new
        @passphrase = passphrase
        @read_timeout = 30
        @verify_mode = verify_mode
        @logger = Net::Hippie.logger
      end

      def execute(uri, request)
        response = http_for(normalize_uri(uri)).request(request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      def get(uri, headers: {}, body: {}, &block)
        request = request_for(Net::HTTP::Get, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def post(uri, headers: {}, body: {}, &block)
        type = Net::HTTP::Post
        request = request_for(type, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def put(uri, headers: {}, body: {}, &block)
        request = request_for(Net::HTTP::Put, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def delete(uri, headers: {}, body: {}, &block)
        type = Net::HTTP::Delete
        request = request_for(type, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      # attempt 1 -> delay 0.1 second
      # attempt 2 -> delay 0.2 second
      # attempt 3 -> delay 0.4 second
      # attempt 4 -> delay 0.8 second
      # attempt 5 -> delay 1.6 second
      # attempt 6 -> delay 3.2 second
      # attempt 7 -> delay 6.4 second
      # attempt 8 -> delay 12.8 second
      def with_retry(retries: 3)
        retries = 0 if retries.nil? || retries.negative?
        0.upto(retries) do |n|
          return yield self
        rescue EOFError, Errno::ECONNRESET, Errno::EINVAL,
               Net::ProtocolError, Timeout::Error => error
          raise error if n == retries

          delay = ((2**n) * 0.1) + Random.rand(0.05) # delay + jitter
          warn("`#{error.message}` Retry: #{n + 1}/#{retries} Delay: #{delay}s")
          sleep delay
        end
      end

      private

      attr_reader :default_headers
      attr_reader :verify_mode
      attr_reader :certificate, :key, :passphrase

      def http_for(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = read_timeout
        http.use_ssl = uri.scheme == 'https'
        http.verify_mode = verify_mode
        http.set_debug_output(logger)
        apply_client_tls_to(http)
        http
      end

      def request_for(type, uri, headers: {}, body: {})
        final_headers = default_headers.merge(headers)
        type.new(uri.to_s, final_headers).tap do |x|
          x.body = mapper.map_from(final_headers, body) unless body.empty?
        end
      end

      def normalize_uri(uri)
        uri.is_a?(URI) ? uri : URI.parse(uri)
      end

      def private_key(type = OpenSSL::PKey::RSA)
        passphrase ? type.new(key, passphrase) : type.new(key)
      end

      def apply_client_tls_to(http)
        return if certificate.nil? || key.nil?

        http.cert = OpenSSL::X509::Certificate.new(certificate)
        http.key = private_key
      end

      def warn(message)
        logger.warn(message)
      end
    end
  end
end
