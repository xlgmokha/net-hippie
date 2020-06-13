# frozen_string_literal: true

module Net
  module Hippie
    # A simple client for connecting with http resources.
    class Client
      DEFAULT_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "net/hippie #{Net::Hippie::VERSION}"
      }.freeze

      attr_reader :mapper, :logger
      attr_reader :follow_redirects

      def initialize(options = {})
        @options = options
        @mapper = options.fetch(:mapper, ContentTypeMapper.new)
        @logger = options.fetch(:logger, Net::Hippie.logger)
        @follow_redirects = options.fetch(:follow_redirects, 0)
        @default_headers = options.fetch(:headers, DEFAULT_HEADERS)
        @connections = Hash.new do |hash, key|
          scheme, host, port = key
          hash[key] = Connection.new(scheme, host, port, options)
        end
      end

      def execute(uri, request, limit: follow_redirects, &block)
        connection = connection_for(uri)
        response = connection.run(request)
        if limit.positive? && response.is_a?(Net::HTTPRedirection)
          url = connection.build_url_for(response['location'])
          request = request_for(Net::HTTP::Get, url)
          execute(url, request, limit: limit - 1, &block)
        else
          block_given? ? yield(request, response) : response
        end
      end

      def get(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Get, headers, body, &block)
      end

      def patch(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Patch, headers, body, &block)
      end

      def post(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Post, headers, body, &block)
      end

      def put(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Put, headers, body, &block)
      end

      def delete(uri, headers: {}, body: {}, &block)
        run(uri, Net::HTTP::Delete, headers, body, &block)
      end

      # attempt 1 -> delay 0.1 second
      # attempt 2 -> delay 0.2 second
      # attempt 3 -> delay 0.4 second
      # attempt 4 -> delay 0.8 second
      # attempt 5 -> delay 1.6 second
      # attempt 6 -> delay 3.2 second
      # attempt 7 -> delay 6.4 second
      # attempt 8 -> delay 12.8 second
      def with_retry(retries: 3)
        retries = 0 if retries.nil? || retries.negative?

        0.upto(retries) do |n|
          attempt(n, retries) do
            return yield self
          end
        end
      end

      private

      attr_reader :default_headers

      def attempt(attempt, max)
        yield
      rescue *CONNECTION_ERRORS => error
        raise error if attempt == max

        delay = ((2**attempt) * 0.1) + Random.rand(0.05) # delay + jitter
        logger.warn("`#{error.message}` #{attempt + 1}/#{max} Delay: #{delay}s")
        sleep delay
      end

      def request_for(type, uri, headers: {}, body: {})
        final_headers = default_headers.merge(headers)
        type.new(URI.parse(uri.to_s), final_headers).tap do |x|
          x.body = mapper.map_from(final_headers, body) unless body.empty?
        end
      end

      def run(uri, http_method, headers, body, &block)
        request = request_for(http_method, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def connection_for(uri)
        uri = URI.parse(uri.to_s)
        @connections[[uri.scheme, uri.host, uri.port]]
      end
    end
  end
end
