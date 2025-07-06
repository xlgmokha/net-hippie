# frozen_string_literal: true

module Net
  module Hippie
    # HTTP client with connection pooling, automatic retries, and JSON-first defaults.
    # 
    # The Client class provides the core HTTP functionality for Net::Hippie, supporting
    # all standard HTTP methods with intelligent defaults for JSON APIs. Features include:
    #
    # * Connection pooling and reuse per host
    # * Automatic retry with exponential backoff
    # * Redirect following with configurable limits  
    # * TLS/SSL support with client certificates
    # * Comprehensive timeout configuration
    # * Pluggable content-type mapping
    #
    # @since 0.1.0
    #
    # == Basic Usage
    #
    #   client = Net::Hippie::Client.new
    #   response = client.get('https://api.github.com/users/octocat')
    #   data = JSON.parse(response.body)
    #
    # == Advanced Configuration
    #
    #   client = Net::Hippie::Client.new(
    #     read_timeout: 30,
    #     open_timeout: 10,
    #     follow_redirects: 5,
    #     headers: { 'User-Agent' => 'MyApp/1.0' }
    #   )
    #
    # == Retry Logic
    #
    #   # Automatic retries with exponential backoff
    #   response = client.with_retry(retries: 3) do |c|
    #     c.post('https://api.example.com/data', body: payload)
    #   end
    #
    # @see Net::Hippie The main module for simple usage
    class Client
      # Default HTTP headers sent with every request.
      # Configured for JSON APIs with a descriptive User-Agent.
      #
      # @since 0.1.0
      DEFAULT_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "net/hippie #{Net::Hippie::VERSION}"
      }.freeze

      # @!attribute [r] mapper
      #   @return [ContentTypeMapper] Content type mapper for request bodies
      # @!attribute [r] logger  
      #   @return [Logger, nil] Logger instance for debugging
      # @!attribute [r] follow_redirects
      #   @return [Integer] Maximum number of redirects to follow
      attr_reader :mapper, :logger, :follow_redirects

      # Creates a new HTTP client with optional configuration.
      #
      # @param options [Hash] Client configuration options
      # @option options [ContentTypeMapper] :mapper Custom content-type mapper
      # @option options [Logger, nil] :logger Logger for request debugging
      # @option options [Integer] :follow_redirects Maximum redirects to follow (default: 0)
      # @option options [Hash] :headers Default headers to merge with requests
      # @option options [Integer] :read_timeout Socket read timeout in seconds (default: 10)
      # @option options [Integer] :open_timeout Socket open timeout in seconds (default: 10)
      # @option options [Integer] :verify_mode SSL verification mode (default: VERIFY_PEER)
      # @option options [String] :certificate Client certificate for mutual TLS
      # @option options [String] :key Private key for client certificate
      # @option options [String] :passphrase Passphrase for encrypted private key
      #
      # @since 0.1.0
      #
      # @example Basic client
      #   client = Net::Hippie::Client.new
      #
      # @example Client with custom timeouts
      #   client = Net::Hippie::Client.new(
      #     read_timeout: 30,
      #     open_timeout: 5
      #   )
      #
      # @example Client with mutual TLS
      #   client = Net::Hippie::Client.new(
      #     certificate: File.read('client.crt'),
      #     key: File.read('client.key'),
      #     passphrase: 'secret'
      #   )
      def initialize(options = {})
        @options = options
        @mapper = options.fetch(:mapper, ContentTypeMapper.new)
        @logger = options.fetch(:logger, Net::Hippie.logger)
        @follow_redirects = options.fetch(:follow_redirects, 0)
        @default_headers = options.fetch(:headers, DEFAULT_HEADERS)
        @connections = Hash.new do |hash, key|
          scheme, host, port = key
          hash[key] = Connection.new(scheme, host, port, options)
        end
      end

      # Executes an HTTP request with automatic redirect following.
      #
      # @param uri [String, URI] The target URI for the request
      # @param request [Net::HTTPRequest] The prepared HTTP request object
      # @param limit [Integer] Maximum number of redirects to follow
      # @yield [request, response] Optional block to process request/response
      # @yieldparam request [Net::HTTPRequest] The HTTP request object
      # @yieldparam response [Net::HTTPResponse] The HTTP response object
      # @return [Net::HTTPResponse] The final HTTP response
      # @raise [Net::ReadTimeout, Net::OpenTimeout] When request times out
      # @since 0.1.0
      def execute(uri, request, limit: follow_redirects, &block)
        connection = connection_for(uri)
        response = connection.run(request)
        if limit.positive? && response.is_a?(Net::HTTPRedirection)
          url = connection.build_url_for(response['location'])
          request = request_for(Net::HTTP::Get, url)
          execute(url, request, limit: limit - 1, &block)
        else
          block_given? ? yield(request, response) : response
        end
      end

      # Performs an HTTP GET request.
      #
      # @param uri [String, URI] The target URI
      # @param headers [Hash] Additional HTTP headers
      # @param body [Hash, String] Request body (typically unused for GET)
      # @yield [request, response] Optional block to process request/response
      # @return [Net::HTTPResponse] The HTTP response
      # @since 0.1.0
      #
      # @example Simple GET
      #   response = client.get('https://api.github.com/users/octocat')
      #
      # @example GET with custom headers
      #   response = client.get('https://api.example.com', 
      #                         headers: { 'Authorization' => 'Bearer token' })
      def get(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Get, headers, body, &block)
      end

      # Performs an HTTP PATCH request.
      #
      # @param uri [String, URI] The target URI
      # @param headers [Hash] Additional HTTP headers
      # @param body [Hash, String] Request body data
      # @yield [request, response] Optional block to process request/response
      # @return [Net::HTTPResponse] The HTTP response
      # @since 0.2.6
      #
      # @example Update resource
      #   response = client.patch('https://api.example.com/users/123',
      #                           body: { name: 'Updated Name' })
      def patch(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Patch, headers, body, &block)
      end

      # Performs an HTTP POST request.
      #
      # @param uri [String, URI] The target URI
      # @param headers [Hash] Additional HTTP headers
      # @param body [Hash, String] Request body data
      # @yield [request, response] Optional block to process request/response
      # @return [Net::HTTPResponse] The HTTP response
      # @since 0.1.0
      #
      # @example Create resource
      #   response = client.post('https://api.example.com/users',
      #                          body: { name: 'John', email: 'john@example.com' })
      def post(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Post, headers, body, &block)
      end

      # Performs an HTTP PUT request.
      #
      # @param uri [String, URI] The target URI
      # @param headers [Hash] Additional HTTP headers
      # @param body [Hash, String] Request body data
      # @yield [request, response] Optional block to process request/response
      # @return [Net::HTTPResponse] The HTTP response
      # @since 0.1.0
      #
      # @example Replace resource
      #   response = client.put('https://api.example.com/users/123',
      #                         body: { name: 'John', email: 'john@example.com' })
      def put(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Put, headers, body, &block)
      end

      # Performs an HTTP DELETE request.
      #
      # @param uri [String, URI] The target URI
      # @param headers [Hash] Additional HTTP headers
      # @param body [Hash, String] Request body (typically unused for DELETE)
      # @yield [request, response] Optional block to process request/response
      # @return [Net::HTTPResponse] The HTTP response
      # @since 0.1.8
      #
      # @example Delete resource
      #   response = client.delete('https://api.example.com/users/123')
      def delete(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Delete, headers, body, &block)
      end

      # Executes HTTP requests with automatic retry and exponential backoff.
      # 
      # Retry logic with exponential backoff and jitter:
      # * Attempt 1 -> delay 0.1 second
      # * Attempt 2 -> delay 0.2 second  
      # * Attempt 3 -> delay 0.4 second
      # * Attempt 4 -> delay 0.8 second
      # * Attempt 5 -> delay 1.6 second
      # * Attempt 6 -> delay 3.2 second
      # * Attempt 7 -> delay 6.4 second
      # * Attempt 8 -> delay 12.8 second
      #
      # Only retries on network-related errors defined in CONNECTION_ERRORS.
      #
      # @param retries [Integer] Maximum number of retry attempts (default: 3)
      # @yield [client] Block that performs the HTTP request
      # @yieldparam client [Client] The client instance to use for requests
      # @return [Net::HTTPResponse] The successful HTTP response
      # @raise [Net::ReadTimeout, Net::OpenTimeout] When all retry attempts fail
      # @since 0.2.1
      #
      # @example Retry a POST request
      #   response = client.with_retry(retries: 5) do |c|
      #     c.post('https://api.unreliable.com/data', body: payload)
      #   end
      #
      # @example No retries
      #   response = client.with_retry(retries: 0) do |c|
      #     c.get('https://api.example.com/health')
      #   end
      def with_retry(retries: 3)
        retries = 0 if retries.nil? || retries.negative?

        0.upto(retries) do |n|
          attempt(n, retries) do
            return yield self
          end
        end
      end

      private

      attr_reader :default_headers

      def attempt(attempt, max)
        yield
      rescue *CONNECTION_ERRORS => error
        raise error if attempt == max

        delay = ((2**attempt) * 0.1) + Random.rand(0.05) # delay + jitter
        logger&.warn("`#{error.message}` #{attempt + 1}/#{max} Delay: #{delay}s")
        sleep delay
      end

      def request_for(type, uri, headers: {}, body: {})
        final_headers = default_headers.merge(headers)
        type.new(URI.parse(uri.to_s), final_headers).tap do |x|
          x.body = mapper.map_from(final_headers, body) unless body.empty?
        end
      end

      def run(uri, http_method, headers, body, &block)
        request = request_for(http_method, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def connection_for(uri)
        uri = URI.parse(uri.to_s)
        @connections[[uri.scheme, uri.host, uri.port]]
      end
    end
  end
end
