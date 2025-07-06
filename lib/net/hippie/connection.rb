# frozen_string_literal: true

require_relative 'rust_backend'

module Net
  module Hippie
    # A connection to a specific host
    class Connection
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

      def run(request)
        @backend.run(request)
      end

      def build_url_for(path)
        @backend.build_url_for(path)
      end

      private

      def create_ruby_backend(scheme, host, port, options)
        # This is the original Ruby implementation wrapped in an object
        # that matches the same interface as RustConnection
        RubyConnection.new(scheme, host, port, options)
      end
    end

    # Wrapper for the original Ruby implementation
    class RubyConnection
      def initialize(scheme, host, port, options = {})
        @scheme = scheme
        @host = host
        @port = port
        
        http = Net::HTTP.new(host, port)
        http.read_timeout = options.fetch(:read_timeout, 10)
        http.open_timeout = options.fetch(:open_timeout, 10)
        http.use_ssl = scheme == 'https'
        http.verify_mode = options.fetch(:verify_mode, Net::Hippie.verify_mode)
        http.set_debug_output(options.fetch(:logger, Net::Hippie.logger))
        apply_client_tls_to(http, options)
        @http = http
      end

      def run(request)
        @http.request(request)
      end

      def build_url_for(path)
        return path if path.start_with?('http')

        "#{@http.use_ssl? ? 'https' : 'http'}://#{@http.address}#{path}"
      end

      private

      def apply_client_tls_to(http, options)
        return if options[:certificate].nil? || options[:key].nil?

        http.cert = OpenSSL::X509::Certificate.new(options[:certificate])
        http.key = private_key(options[:key], options[:passphrase])
      end

      def private_key(key, passphrase, type = OpenSSL::PKey::RSA)
        passphrase ? type.new(key, passphrase) : type.new(key)
      end
    end
  end
end
