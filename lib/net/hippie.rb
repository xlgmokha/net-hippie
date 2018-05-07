require 'json'
require 'logger'
require 'net/http'
require 'openssl'

require 'net/hippie/version'
require 'net/hippie/json_mapper'
require 'net/hippie/client'

module Net
  module Hippie
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end
