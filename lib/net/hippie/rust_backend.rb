# frozen_string_literal: true

module Net
  module Hippie
    # Rust backend integration and availability detection.
    #
    # The RustBackend module manages the optional high-performance Rust HTTP client
    # backend. It provides automatic detection of Rust extension availability and
    # environment-based enabling/disabling of the Rust backend.
    #
    # == Backend Selection Logic
    #
    # 1. Check if NET_HIPPIE_RUST environment variable is set to 'true'
    # 2. Verify that the Rust extension (net_hippie_ext) can be loaded
    # 3. If both conditions are met, use RustConnection
    # 4. Otherwise, fall back to RubyConnection
    #
    # == Performance Benefits
    #
    # When enabled, the Rust backend provides:
    # * Significantly faster HTTP requests using reqwest
    # * Better concurrency with Tokio async runtime
    # * Lower memory usage with zero-cost abstractions
    # * Type safety with compile-time guarantees
    #
    # @since 2.0.0
    #
    # == Environment Configuration
    #
    #   # Enable Rust backend
    #   ENV['NET_HIPPIE_RUST'] = 'true'
    #
    #   # Check availability and status
    #   puts "Rust available: #{Net::Hippie::RustBackend.available?}"
    #   puts "Rust enabled: #{Net::Hippie::RustBackend.enabled?}"
    #
    # @see RUST_BACKEND.md Detailed setup and usage documentation
    module RustBackend
      @rust_available = nil

      # Checks if the Rust extension is available for loading.
      #
      # This method attempts to require the 'net_hippie_ext' native extension
      # and caches the result. The extension is built from Rust source code
      # using Magnus for Ruby-Rust integration.
      #
      # @return [Boolean] true if Rust extension loaded successfully
      # @since 2.0.0
      #
      # @example Check Rust availability
      #   if Net::Hippie::RustBackend.available?
      #     puts "Rust backend ready!"
      #   else
      #     puts "Using Ruby backend (Rust not available)"
      #   end
      def self.available?
        return @rust_available unless @rust_available.nil?

        @rust_available = begin
          require 'net_hippie_ext'
          true
        rescue LoadError
          false
        end
      end

      # Checks if the Rust backend is both available and enabled.
      #
      # Returns true only when:
      # 1. NET_HIPPIE_RUST environment variable is set to 'true'
      # 2. The Rust extension is available (compiled and loadable)
      #
      # @return [Boolean] true if Rust backend should be used
      # @since 2.0.0
      #
      # @example Check if Rust backend will be used
      #   ENV['NET_HIPPIE_RUST'] = 'true'
      #   if Net::Hippie::RustBackend.enabled?
      #     puts "All HTTP requests will use Rust backend"
      #   else
      #     puts "Falling back to Ruby backend"
      #   end
      def self.enabled?
        ENV['NET_HIPPIE_RUST'] == 'true' && available?
      end

      # Adapter that makes Rust HTTP responses compatible with Net::HTTPResponse interface.
      #
      # The ResponseAdapter provides a compatibility layer between Rust HTTP responses
      # and Ruby's Net::HTTPResponse objects. This ensures that existing code works
      # unchanged when switching between Ruby and Rust backends.
      #
      # == Compatibility Features
      #
      # * Status code access via #code method
      # * Response body access via #body method
      # * Header access via #[] method
      # * Response class detection via #class method
      # * Type checking via #is_a? and #kind_of?
      #
      # @since 2.0.0
      #
      # == Supported Response Classes
      #
      # * Net::HTTPOK (200)
      # * Net::HTTPCreated (201)
      # * Net::HTTPRedirection (3xx)
      # * Net::HTTPClientError (4xx)
      # * Net::HTTPServerError (5xx)
      #
      # @see Net::HTTPResponse The Ruby standard library response interface
      class ResponseAdapter
        # Creates a new response adapter from a Rust HTTP response.
        #
        # @param rust_response [RustResponse] The Rust HTTP response object
        # @since 2.0.0
        def initialize(rust_response)
          @rust_response = rust_response
          @code = rust_response.code
          @body = rust_response.body
        end

        # Returns the HTTP status code.
        #
        # @return [String] HTTP status code (e.g., "200", "404")
        # @since 2.0.0
        def code
          @code
        end

        # Returns the response body content.
        #
        # @return [String] HTTP response body
        # @since 2.0.0
        def body
          @body
        end

        # Retrieves a response header value by name.
        #
        # @param header_name [String, Symbol] Header name (case-insensitive)
        # @return [String, nil] Header value or nil if not found
        # @since 2.0.0
        #
        # @example Get content type
        #   content_type = response['Content-Type']
        #   location = response[:location]
        def [](header_name)
          @rust_response[header_name.to_s]
        end

        # Returns the appropriate Net::HTTP response class based on status code.
        #
        # Maps HTTP status codes to their corresponding Net::HTTP class constants
        # to maintain compatibility with Ruby HTTP library expectations.
        #
        # @return [Class] Net::HTTP response class constant
        # @since 2.0.0
        #
        # @example Check response type
        #   response.class # => Net::HTTPOK (for 200 status)
        #   response.class # => Net::HTTPNotFound (for 404 status)
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

        # Checks if this response is an instance of the given class.
        #
        # Provides compatibility with Ruby's type checking by delegating
        # to the mapped response class while supporting normal inheritance.
        #
        # @param klass [Class] Class to check against
        # @return [Boolean] true if response matches the class
        # @since 2.0.0
        #
        # @example Type checking
        #   response.is_a?(Net::HTTPOK)          # => true (for 200 status)
        #   response.is_a?(Net::HTTPRedirection) # => true (for 3xx status)
        def is_a?(klass)
          self.class == klass || super
        end

        # Alias for #is_a? to maintain Ruby compatibility.
        #
        # @param klass [Class] Class to check against
        # @return [Boolean] true if response matches the class
        # @since 2.0.0
        def kind_of?(klass)
          is_a?(klass)
        end
      end
    end
  end
end
