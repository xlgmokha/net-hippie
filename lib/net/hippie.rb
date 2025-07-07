# frozen_string_literal: true

require 'base64'
require 'json'
require 'logger'
require 'net/http'
require 'openssl'

require 'net/hippie/version'
require 'net/hippie/client'
require 'net/hippie/connection'
require 'net/hippie/content_type_mapper'
require 'net/hippie/rust_backend'

module Net
  # Net::Hippie is a lightweight wrapper around Ruby's net/http library that simplifies 
  # HTTP requests with JSON-first defaults and optional high-performance Rust backend.
  #
  # @since 0.1.0
  #
  # == Features
  #
  # * JSON-first API with automatic content-type handling
  # * Built-in retry logic with exponential backoff
  # * Connection pooling and reuse
  # * TLS/SSL support with client certificates
  # * Optional Rust backend for enhanced performance (v2.0+)
  # * Automatic redirect following
  # * Comprehensive error handling
  #
  # == Basic Usage
  #
  #   # Simple GET request
  #   response = Net::Hippie.get('https://api.github.com/users/octocat')
  #   data = JSON.parse(response.body)
  #
  #   # POST with JSON body
  #   response = Net::Hippie.post('https://httpbin.org/post', 
  #                               body: { name: 'hippie', version: '2.0' })
  #
  # == Rust Backend (v2.0+)
  #
  #   # Enable high-performance Rust backend
  #   ENV['NET_HIPPIE_RUST'] = 'true'
  #   response = Net::Hippie.get('https://api.example.com') # Uses Rust!
  #
  # @see Client The main client class for advanced usage
  # @see https://github.com/xlgmokha/net-hippie Documentation and examples
  module Hippie
    # List of network-related exceptions that should trigger automatic retries.
    # These errors typically indicate transient network issues that may resolve
    # on subsequent attempts.
    #
    # @since 0.2.7
    CONNECTION_ERRORS = [
      EOFError,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::EINVAL,
      Net::OpenTimeout,
      Net::ProtocolError,
      Net::ReadTimeout,
      OpenSSL::OpenSSLError,
      OpenSSL::SSL::SSLError,
      SocketError,
      Timeout::Error
    ].freeze

    # Gets the current logger instance.
    # Defaults to a null logger (no output) if not explicitly set.
    #
    # @return [Logger, nil] The current logger instance
    # @since 1.2.0
    #
    # @example
    #   Net::Hippie.logger = Logger.new(STDOUT)
    #   logger = Net::Hippie.logger
    def self.logger
      @logger ||= Logger.new(nil)
    end

    # Sets the logger for HTTP request debugging and error reporting.
    #
    # @param logger [Logger, nil] Logger instance or nil to disable logging
    # @return [Logger, nil] The assigned logger
    # @since 1.2.0
    #
    # @example Enable debug logging
    #   Net::Hippie.logger = Logger.new(STDERR)
    #   Net::Hippie.logger.level = Logger::DEBUG
    #
    # @example Disable logging
    #   Net::Hippie.logger = nil
    def self.logger=(logger)
      @logger = logger
    end

    # Gets the default SSL verification mode for HTTPS connections.
    #
    # @return [Integer] OpenSSL verification mode constant
    # @since 0.2.3
    def self.verify_mode
      @verify_mode ||= OpenSSL::SSL::VERIFY_PEER
    end

    # Sets the default SSL verification mode for HTTPS connections.
    #
    # @param mode [Integer] OpenSSL verification mode constant
    # @return [Integer] The assigned verification mode
    # @since 0.2.3
    #
    # @example Disable SSL verification (not recommended for production)
    #   Net::Hippie.verify_mode = OpenSSL::SSL::VERIFY_NONE
    def self.verify_mode=(mode)
      @verify_mode = mode
    end

    # Generates a Basic Authentication header value.
    #
    # @param username [String] The username for authentication
    # @param password [String] The password for authentication
    # @return [String] Base64-encoded Basic auth header value
    # @since 0.2.1
    #
    # @example
    #   auth_header = Net::Hippie.basic_auth('user', 'pass')
    #   response = Net::Hippie.get('https://api.example.com', 
    #                              headers: { 'Authorization' => auth_header })
    def self.basic_auth(username, password)
      "Basic #{::Base64.strict_encode64("#{username}:#{password}")}"
    end

    # Generates a Bearer Token authentication header value.
    #
    # @param token [String] The bearer token for authentication
    # @return [String] Bearer auth header value
    # @since 0.2.1
    #
    # @example
    #   auth_header = Net::Hippie.bearer_auth('your-api-token')
    #   response = Net::Hippie.get('https://api.example.com',
    #                              headers: { 'Authorization' => auth_header })
    def self.bearer_auth(token)
      "Bearer #{token}"
    end

    # Delegates HTTP method calls to the default client with automatic retry.
    # Supports all HTTP methods available on the Client class (get, post, put, etc.).
    #
    # @param symbol [Symbol] The HTTP method name to call
    # @param args [Array] Arguments to pass to the HTTP method
    # @return [Net::HTTPResponse] The HTTP response from the request
    # @raise [Net::ReadTimeout, Net::OpenTimeout] When request times out
    # @raise [Errno::ECONNREFUSED] When connection is refused
    # @since 1.0.0
    #
    # @example GET request
    #   response = Net::Hippie.get('https://api.github.com/users/octocat')
    #
    # @example POST request
    #   response = Net::Hippie.post('https://httpbin.org/post', body: { key: 'value' })
    #
    # @see Client#get, Client#post, Client#put, Client#patch, Client#delete
    def self.method_missing(symbol, *args)
      default_client.with_retry(retries: 3) do |client|
        client.public_send(symbol, *args)
      end || super
    end

    # Checks if the module responds to HTTP method calls by delegating to Client.
    #
    # @param name [Symbol] The method name to check
    # @param _include_private [Boolean] Whether to include private methods (ignored)
    # @return [Boolean] True if the method is supported
    # @since 1.0.0
    def self.respond_to_missing?(name, _include_private = false)
      Client.public_instance_methods.include?(name.to_sym) || super
    end

    # Gets the shared default client instance used for module-level HTTP calls.
    # The client is configured with automatic redirects and uses the module logger.
    #
    # @return [Client] The default client instance
    # @since 1.0.0
    #
    # @example Access the default client directly
    #   client = Net::Hippie.default_client
    #   client.get('https://api.example.com')
    def self.default_client
      @default_client ||= Client.new(follow_redirects: 3, logger: logger)
    end
  end
end
