module Net
  module Hippie
    class JsonMapper
      def map_from(hash)
        JSON.generate(hash)
      end
    end
  end
end
