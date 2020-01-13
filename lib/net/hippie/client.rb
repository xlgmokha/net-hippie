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

      attr_accessor :mapper, :read_timeout, :open_timeout, :logger
      attr_accessor :follow_redirects

      def initialize(certificate: nil, headers: DEFAULT_HEADERS,
        key: nil, passphrase: nil, verify_mode: Net::Hippie.verify_mode)
        @certificate = certificate
        @default_headers = headers
        @key = key
        @mapper = ContentTypeMapper.new
        @passphrase = passphrase
        @read_timeout = 30
        @verify_mode = verify_mode
        @logger = Net::Hippie.logger
        @follow_redirects = 0
      end

      def execute(uri, request)
        response = follow(limit: follow_redirects) do
          http_for(normalize_uri(uri)).request(request)
        end
        block_given? ? yield(request, response) : response
      end

      def get(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Get, headers, body, &block)
      end

      def patch(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Patch, headers, body, &block)
      end

      def post(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Post, headers, body, &block)
      end

      def put(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Put, headers, body, &block)
      end

      def delete(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Delete, headers, body, &block)
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
          attempt(n, retries) do
            return yield self
          end
        end
      end

      private

      attr_reader :default_headers, :verify_mode
      attr_reader :certificate, :key, :passphrase

      def attempt(attempt, max)
        yield
      rescue *CONNECTION_ERRORS => error
        raise error if attempt == max

        delay = ((2**attempt) * 0.1) + Random.rand(0.05) # delay + jitter
        warn("`#{error.message}` Retry: #{attempt + 1}/#{max} Delay: #{delay}s")
        sleep delay
      end

      def http_for(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = read_timeout
        http.open_timeout = open_timeout if open_timeout
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

      def follow(limit: 0, &block)
        response = yield
        redirected = limit.positive? && response.is_a?(Net::HTTPRedirection)
        redirected ? follow(limit: limit - 1, &block) : response
      end

      def run(uri, http_method, headers, body, &block)
        request = request_for(http_method, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end
    end
  end
end
