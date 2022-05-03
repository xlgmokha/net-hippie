# frozen_string_literal: true

module Net
  module Hippie
    # A connection to a specific host
    class Connection
      def initialize(scheme, host, port, options = {})
        http = Net::HTTP.new(host, port)
        http.read_timeout = options.fetch(:read_timeout, 10)
        http.open_timeout = options.fetch(:open_timeout, 10)
        http.use_ssl = scheme == 'https'
        http.verify_mode = options.fetch(:verify_mode, Net::Hippie.verify_mode)
        http.set_debug_output(options.fetch(:logger, Net::Hippie.logger)) if options[:enable_debug_output] == true
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
