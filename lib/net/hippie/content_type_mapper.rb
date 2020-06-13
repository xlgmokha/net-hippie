# frozen_string_literal: true

module Net
  module Hippie
    # Converts a ruby hash into a JSON string
    class ContentTypeMapper
      def map_from(headers, body)
        return body if body.is_a?(String)

        content_type = headers['Content-Type'] || ''
        return JSON.generate(body) if content_type.include?('json')

        body
      end
    end
  end
end
