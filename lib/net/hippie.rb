# frozen_string_literal: true

require 'base64'
require 'json'
require 'logger'
require 'net/http'
require 'openssl'

require 'net/hippie/version'
require 'net/hippie/content_type_mapper'
require 'net/hippie/client'
require 'net/hippie/api'

module Net
  # net/http for hippies.
  module Hippie
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.basic_auth(username, password)
      "Basic #{::Base64.strict_encode64("#{username}:#{password}")}"
    end
  end
end
