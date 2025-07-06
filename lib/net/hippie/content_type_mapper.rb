# frozen_string_literal: true

module Net
  module Hippie
    # Content-type aware request body serialization.
    #
    # The ContentTypeMapper handles automatic serialization of request bodies
    # based on the Content-Type header. It provides intelligent defaults for
    # JSON APIs while supporting custom serialization strategies.
    #
    # == Default Behavior
    #
    # * JSON content types -> Automatic JSON.generate() serialization
    # * String bodies -> Passed through unchanged
    # * Other content types -> No transformation (body as-is)
    #
    # @since 0.1.0
    #
    # == Usage
    #
    #   mapper = Net::Hippie::ContentTypeMapper.new
    #   
    #   # JSON serialization
    #   json_body = mapper.map_from(
    #     { 'Content-Type' => 'application/json' },
    #     { name: 'Alice', age: 30 }
    #   )
    #   # => '{"name":"Alice","age":30}'
    #   
    #   # String pass-through
    #   xml_body = mapper.map_from(
    #     { 'Content-Type' => 'application/xml' },
    #     '<user><name>Alice</name></user>'
    #   )
    #   # => '<user><name>Alice</name></user>'
    #
    # @see Client#initialize The :mapper option for custom mappers
    class ContentTypeMapper
      # Maps request body data based on Content-Type header.
      #
      # Performs automatic serialization for known content types:
      # * application/json -> JSON.generate() 
      # * application/*+json -> JSON.generate()
      # * String bodies -> No transformation
      # * Other types -> No transformation
      #
      # @param headers [Hash] HTTP headers (must include 'Content-Type')
      # @param body [Object] Request body data to serialize
      # @return [String, Object] Serialized body or original object
      # @since 0.1.0
      #
      # @example JSON serialization
      #   mapper = ContentTypeMapper.new
      #   result = mapper.map_from(
      #     { 'Content-Type' => 'application/json' },
      #     { user: { name: 'Alice', email: 'alice@example.com' } }
      #   )
      #   # => '{"user":{"name":"Alice","email":"alice@example.com"}}'
      #
      # @example String pass-through
      #   result = mapper.map_from(
      #     { 'Content-Type' => 'text/plain' },
      #     'Hello, World!'
      #   )
      #   # => 'Hello, World!'
      #
      # @example Custom JSON content type
      #   result = mapper.map_from(
      #     { 'Content-Type' => 'application/vnd.api+json' },
      #     { data: { type: 'users', attributes: { name: 'Alice' } } }
      #   )
      #   # => '{"data":{"type":"users","attributes":{"name":"Alice"}}}'
      def map_from(headers, body)
        return body if body.is_a?(String)

        content_type = headers['Content-Type'] || ''
        return JSON.generate(body) if content_type.include?('json')

        body
      end
    end
  end
end
