# frozen_string_literal: true

module Net
  module Hippie
    # Rust backend integration
    module RustBackend
      @rust_available = nil

      def self.available?
        return @rust_available unless @rust_available.nil?

        @rust_available = begin
          require 'net_hippie_ext'
          true
        rescue LoadError
          false
        end
      end

      def self.enabled?
        ENV['NET_HIPPIE_RUST'] == 'true' && available?
      end

      # Adapter to make RustResponse behave like Net::HTTPResponse
      class ResponseAdapter
        def initialize(rust_response)
          @rust_response = rust_response
          @code = rust_response.code
          @body = rust_response.body
        end

        def code
          @code
        end

        def body
          @body
        end

        def [](header_name)
          @rust_response[header_name.to_s]
        end

        def class
          case @code.to_i
          when 200
            Net::HTTPOK
          when 201
            Net::HTTPCreated
          when 300..399
            Net::HTTPRedirection
          when 400..499
            Net::HTTPClientError
          when 500..599
            Net::HTTPServerError
          else
            Net::HTTPResponse
          end
        end

        # Make it behave like the expected response class
        def is_a?(klass)
          self.class == klass || super
        end

        def kind_of?(klass)
          is_a?(klass)
        end
      end
    end
  end
end