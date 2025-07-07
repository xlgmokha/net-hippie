# frozen_string_literal: true

module Net
  module Hippie
    # Connection abstraction layer that supports both Ruby and Rust backends.
    #
    # The Connection class provides a unified interface for HTTP connections,
    # automatically selecting between the Ruby implementation and the optional
    # high-performance Rust backend based on availability and configuration.
    #
    # Backend selection logic:
    # 1. If NET_HIPPIE_RUST=true and Rust extension available -> RustConnection
    # 2. Otherwise -> RubyConnection (classic net/http implementation)
    #
    # @since 0.1.0
    # @since 2.0.0 Added Rust backend support
    #
    # == Backend Switching
    #
    #   # Enable Rust backend (requires compilation)
    #   ENV['NET_HIPPIE_RUST'] = 'true'
    #   connection = Net::Hippie::Connection.new('https', 'api.example.com', 443)
    #   # Uses RustConnection if available, falls back to RubyConnection
    #
    # @see RubyConnection The Ruby/net-http implementation
    # @see RustConnection The optional Rust implementation  
    class Connection
      # Creates a new connection with automatic backend selection.
      #
      # @param scheme [String] URL scheme ('http' or 'https')
      # @param host [String] Target hostname
      # @param port [Integer] Target port number
      # @param options [Hash] Connection configuration options
      # @option options [Integer] :read_timeout Socket read timeout in seconds
      # @option options [Integer] :open_timeout Socket connection timeout in seconds
      # @option options [Integer] :verify_mode SSL verification mode
      # @option options [String] :certificate Client certificate for mutual TLS
      # @option options [String] :key Private key for client certificate
      # @option options [String] :passphrase Passphrase for encrypted private key
      # @option options [Logger] :logger Logger for connection debugging
      #
      # @since 0.1.0
      # @since 2.0.0 Added automatic backend selection
      def initialize(scheme, host, port, options = {})
        @scheme = scheme
        @host = host
        @port = port
        @options = options

        if RustBackend.enabled?
          require_relative 'rust_connection'
          @backend = RustConnection.new(scheme, host, port, options)
        else
          @backend = create_ruby_backend(scheme, host, port, options)
        end
      end

      # Executes an HTTP request using the selected backend.
      #
      # @param request [Net::HTTPRequest] The HTTP request to execute
      # @return [Net::HTTPResponse] The HTTP response
      # @raise [Net::ReadTimeout, Net::OpenTimeout] When request times out
      # @since 0.1.0
      def run(request)
        @backend.run(request)
      end

      # Builds a complete URL from a path, handling absolute and relative URLs.
      #
      # @param path [String] URL path (absolute or relative)
      # @return [String] Complete URL
      # @since 0.1.0
      def build_url_for(path)
        @backend.build_url_for(path)
      end

      private

      # Creates the Ruby backend implementation.
      #
      # @param scheme [String] URL scheme
      # @param host [String] Target hostname  
      # @param port [Integer] Target port
      # @param options [Hash] Connection options
      # @return [RubyConnection] Ruby backend instance
      # @since 2.0.0
      def create_ruby_backend(scheme, host, port, options)
        # This is the original Ruby implementation wrapped in an object
        # that matches the same interface as RustConnection
        RubyConnection.new(scheme, host, port, options)
      end
    end

    # Ruby implementation of HTTP connections using net/http.
    #
    # This class provides the traditional net/http-based HTTP client functionality
    # that has been the backbone of Net::Hippie since its inception. It supports
    # all standard HTTP features including SSL/TLS, client certificates, and
    # comprehensive timeout configuration.
    #
    # @since 2.0.0 Extracted from Connection class
    # @see Connection The main connection interface
    class RubyConnection
      # Creates a new Ruby HTTP connection using net/http.
      #
      # @param scheme [String] URL scheme ('http' or 'https')
      # @param host [String] Target hostname
      # @param port [Integer] Target port number
      # @param options [Hash] Connection configuration options
      # @option options [Integer] :read_timeout Socket read timeout (default: 10)
      # @option options [Integer] :open_timeout Socket connection timeout (default: 10)
      # @option options [Integer] :verify_mode SSL verification mode
      # @option options [String] :certificate Client certificate for mutual TLS
      # @option options [String] :key Private key for client certificate
      # @option options [String] :passphrase Passphrase for encrypted private key
      # @option options [Logger] :logger Logger for connection debugging
      #
      # @since 2.0.0
      def initialize(scheme, host, port, options = {})
        @scheme = scheme
        @host = host
        @port = port
        
        http = Net::HTTP.new(host, port)
        http.read_timeout = options.fetch(:read_timeout, 10)
        http.open_timeout = options.fetch(:open_timeout, 10)
        http.use_ssl = scheme == 'https'
        http.verify_mode = options.fetch(:verify_mode, Net::Hippie.verify_mode)
        http.set_debug_output(options[:logger]) if options[:logger]
        apply_client_tls_to(http, options)
        @http = http
      end

      # Executes an HTTP request using net/http.
      #
      # @param request [Net::HTTPRequest] The HTTP request to execute
      # @return [Net::HTTPResponse] The HTTP response
      # @raise [Net::ReadTimeout] When read timeout expires
      # @raise [Net::OpenTimeout] When connection timeout expires
      # @since 2.0.0
      def run(request)
        @http.request(request)
      end

      # Builds a complete URL from a path.
      #
      # @param path [String] URL path (absolute URLs returned as-is)
      # @return [String] Complete URL with scheme, host, and path
      # @since 2.0.0
      #
      # @example Relative path
      #   connection.build_url_for('/api/users') 
      #   # => "https://api.example.com/api/users"
      #
      # @example Absolute URL
      #   connection.build_url_for('https://other.com/path')
      #   # => "https://other.com/path"
      def build_url_for(path)
        return path if path.start_with?('http')

        "#{@http.use_ssl? ? 'https' : 'http'}://#{@http.address}#{path}"
      end

      private

      # Applies client TLS certificate configuration to the HTTP connection.
      #
      # @param http [Net::HTTP] The HTTP connection object
      # @param options [Hash] TLS configuration options
      # @option options [String] :certificate Client certificate in PEM format
      # @option options [String] :key Private key in PEM format
      # @option options [String] :passphrase Optional passphrase for encrypted key
      # @since 2.0.0
      def apply_client_tls_to(http, options)
        return if options[:certificate].nil? || options[:key].nil?

        http.cert = OpenSSL::X509::Certificate.new(options[:certificate])
        http.key = private_key(options[:key], options[:passphrase])
      end

      # Creates a private key object from PEM data.
      #
      # @param key [String] Private key in PEM format
      # @param passphrase [String, nil] Optional passphrase for encrypted keys
      # @param type [Class] OpenSSL key class (default: RSA)
      # @return [OpenSSL::PKey] Private key object
      # @since 2.0.0
      def private_key(key, passphrase, type = OpenSSL::PKey::RSA)
        passphrase ? type.new(key, passphrase) : type.new(key)
      end
    end
  end
end
