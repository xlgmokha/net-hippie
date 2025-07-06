# frozen_string_literal: true

require_relative 'rust_backend'

module Net
  module Hippie
    # Rust-powered connection that mimics the Ruby Connection interface
    class RustConnection
      def initialize(scheme, host, port, options = {})
        @scheme = scheme
        @host = host
        @port = port
        @options = options
        
        # Create the Rust client (simplified version for now)
        @rust_client = Net::Hippie::RustClient.new
      end

      def run(request)
        url = build_url_for(request.path)
        headers = {} # Simplified for now
        body = request.body || ''
        method = extract_method(request)

        begin
          rust_response = @rust_client.public_send(method.downcase, url, headers, body)
          RustBackend::ResponseAdapter.new(rust_response)
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