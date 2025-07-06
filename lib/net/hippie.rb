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
  # net/http for hippies.
  module Hippie
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

    def self.logger
      @logger ||= Logger.new(nil)
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.verify_mode
      @verify_mode ||= OpenSSL::SSL::VERIFY_PEER
    end

    def self.verify_mode=(mode)
      @verify_mode = mode
    end

    def self.basic_auth(username, password)
      "Basic #{::Base64.strict_encode64("#{username}:#{password}")}"
    end

    def self.bearer_auth(token)
      "Bearer #{token}"
    end

    def self.method_missing(symbol, *args)
      default_client.with_retry(retries: 3) do |client|
        client.public_send(symbol, *args)
      end || super
    end

    def self.respond_to_missing?(name, _include_private = false)
      Client.public_instance_methods.include?(name.to_sym) || super
    end

    def self.default_client
      @default_client ||= Client.new(follow_redirects: 3, logger: logger)
    end
  end
end
