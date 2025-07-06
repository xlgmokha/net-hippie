# frozen_string_literal: true

require_relative 'rust_backend'

module Net
  module Hippie
    # Rust-powered HTTP connection with debug logging support.
    #
    # RustConnection provides a high-performance HTTP client using Rust's reqwest library
    # while maintaining full compatibility with the Ruby backend interface, including
    # comprehensive debug logging that matches Net::HTTP's set_debug_output behavior.
    #
    # == Debug Logging
    #
    # When a logger is provided, RustConnection outputs detailed HTTP transaction logs
    # in the same format as Net::HTTP:
    #
    #   logger = File.open('http_debug.log', 'w')
    #   connection = RustConnection.new('https', 'api.example.com', 443, logger: logger)
    #   
    #   # Output format:
    #   # -> "GET https://api.example.com/users HTTP/1.1"
    #   # -> "accept: application/json"
    #   # -> "user-agent: net/hippie 2.0.0"
    #   # -> ""
    #   # <- "HTTP/1.1 200"
    #   # <- "content-type: application/json"
    #   # <- ""
    #   # <- "{\"users\":[...]}"
    #
    # @since 2.0.0
    # @see RubyConnection The Ruby/net-http implementation
    # @see Connection The backend abstraction layer
    class RustConnection
      def initialize(scheme, host, port, options = {})
        @scheme = scheme
        @host = host
        @port = port
        @options = options
        @logger = options[:logger]
        
        # Create the Rust client (simplified version for now)
        @rust_client = Net::Hippie::RustClient.new
      end

      def run(request)
        url = build_url_for(request.path)
        headers = extract_headers(request)
        body = request.body || ''
        method = extract_method(request)

        # Debug logging (mimics Net::HTTP's set_debug_output behavior)
        log_request(method, url, headers, body) if @logger

        begin
          rust_response = @rust_client.public_send(method.downcase, url, headers, body)
          response = RustBackend::ResponseAdapter.new(rust_response)
          
          # Debug log response
          log_response(response) if @logger
          
          response
        rescue => e
          # Map Rust errors to Ruby equivalents
          raise map_rust_error(e)
        end
      end

      def build_url_for(path)
        return path if path.start_with?('http')

        port_suffix = (@port == 80 && @scheme == 'http') || (@port == 443 && @scheme == 'https') ? '' : ":#{@port}"
        "#{@scheme}://#{@host}#{port_suffix}#{path}"
      end

      private

      def extract_headers(request)
        headers = {}
        request.each_header do |key, value|
          headers[key] = value
        end
        headers
      end

      def extract_method(request)
        request.class.name.split('::').last.sub('HTTP', '').downcase
      end

      # Logs HTTP request details in Net::HTTP debug format.
      #
      # Outputs request line, headers, and body using the same format as
      # Net::HTTP's set_debug_output for consistent debugging experience.
      #
      # @param method [String] HTTP method (GET, POST, etc.)
      # @param url [String] Complete request URL
      # @param headers [Hash] Request headers
      # @param body [String] Request body content
      # @since 2.0.0
      def log_request(method, url, headers, body)
        # Format similar to Net::HTTP's debug output
        @logger << "-> \"#{method.upcase} #{url} HTTP/1.1\"\n"
        
        # Log headers
        headers.each do |key, value|
          @logger << "-> \"#{key.downcase}: #{value}\"\n"
        end
        
        @logger << "-> \"\"\n"  # Empty line
        
        # Log body if present
        if body && !body.empty?
          @logger << "-> \"#{body}\"\n"
        end
        
        @logger.flush if @logger.respond_to?(:flush)
      end

      # Logs HTTP response details in Net::HTTP debug format.
      #
      # Outputs response status, headers, and body (truncated if large) using
      # the same format as Net::HTTP's set_debug_output.
      #
      # @param response [RustBackend::ResponseAdapter] HTTP response object
      # @since 2.0.0
      def log_response(response)
        # Format similar to Net::HTTP's debug output
        @logger << "<- \"HTTP/1.1 #{response.code}\"\n"
        
        # Log some common response headers if available
        %w[content-type content-length location server date].each do |header|
          value = response[header]
          if value
            @logger << "<- \"#{header}: #{value}\"\n"
          end
        end
        
        @logger << "<- \"\"\n"  # Empty line
        
        # Log response body (truncated if too long)
        body = response.body
        if body && !body.empty?
          display_body = body.length > 1000 ? "#{body[0...1000]}...[truncated]" : body
          @logger << "<- \"#{display_body}\"\n"
        end
        
        @logger.flush if @logger.respond_to?(:flush)
      end

      def map_rust_error(error)
        case error.message
        when /Net::ReadTimeout/
          Net::ReadTimeout.new
        when /Net::OpenTimeout/
          Net::OpenTimeout.new
        when /Errno::ECONNREFUSED/
          Errno::ECONNREFUSED.new
        when /Errno::ECONNRESET/
          Errno::ECONNRESET.new
        when /timeout/i
          Net::ReadTimeout.new
        else
          error
        end
      end
    end
  end
end