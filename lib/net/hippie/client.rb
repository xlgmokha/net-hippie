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

      attr_reader :mapper, :logger
      attr_reader :follow_redirects

      def initialize(options = {})
        @options = options
        @mapper = options.fetch(:mapper, ContentTypeMapper.new)
        @logger = options.fetch(:logger, Net::Hippie.logger)
        @follow_redirects = options.fetch(:follow_redirects, 0)
        @http_connections = Hash.new do |hash, key|
          scheme, host, port = key
          build_http_for(scheme, host, port).tap { |http| hash[key] = http }
        end
      end

      def execute(uri, request, limit: follow_redirects, &block)
        http = http_for(uri)
        response = http.request(request)
        if limit.positive? && response.is_a?(Net::HTTPRedirection)
          url = build_url_for(http, response['location'])
          request = request_for(Net::HTTP::Get, url)
          execute(url, request, limit: limit - 1, &block)
        else
          block_given? ? yield(request, response) : response
        end
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

      def default_headers
        @options.fetch(:headers, DEFAULT_HEADERS)
      end

      def attempt(attempt, max)
        yield
      rescue *CONNECTION_ERRORS => error
        raise error if attempt == max

        delay = ((2**attempt) * 0.1) + Random.rand(0.05) # delay + jitter
        logger.warn("`#{error.message}` #{attempt + 1}/#{max} Delay: #{delay}s")
        sleep delay
      end

      def build_http_for(scheme, host, port)
        http = Net::HTTP.new(host, port)
        http.read_timeout = @options.fetch(:read_timeout, 10)
        http.open_timeout = @options.fetch(:open_timeout, 10)
        http.use_ssl = scheme == 'https'
        http.verify_mode = @options.fetch(:verify_mode, Net::Hippie.verify_mode)
        http.set_debug_output(logger)
        apply_client_tls_to(http)
        http
      end

      def request_for(type, uri, headers: {}, body: {})
        final_headers = default_headers.merge(headers)
        type.new(URI.parse(uri.to_s), final_headers).tap do |x|
          x.body = mapper.map_from(final_headers, body) unless body.empty?
        end
      end

      def private_key(key, passphrase, type = OpenSSL::PKey::RSA)
        passphrase ? type.new(key, passphrase) : type.new(key)
      end

      def apply_client_tls_to(http)
        return if @options[:certificate].nil? || @options[:key].nil?

        http.cert = OpenSSL::X509::Certificate.new(@options[:certificate])
        http.key = private_key(@options[:key], @options[:passphrase])
      end

      def run(uri, http_method, headers, body, &block)
        request = request_for(http_method, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def build_url_for(http, path)
        return path if path.start_with?('http')

        "#{http.use_ssl? ? 'https' : 'http'}://#{http.address}#{path}"
      end

      def http_for(uri)
        uri = URI.parse(uri.to_s)
        @http_connections[[uri.scheme, uri.host, uri.port]]
      end
    end
  end
end
