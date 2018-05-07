module Net
  module Hippie
    # Converts a ruby hash into a JSON string
    class JsonMapper
      def map_from(hash)
        JSON.generate(hash)
      end
    end
  end
end
