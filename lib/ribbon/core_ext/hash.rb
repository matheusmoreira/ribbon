require 'ribbon/object'

module Ribbon
  module CoreExt

    # Includes a method to convert hashes to ribbons.
    module Hash

      def to_ribbon
        ::Ribbon::Object.new self
      end

      alias to_rbon to_ribbon

    end

    class ::Hash; include ::Ribbon::CoreExt::Hash; end

  end
end
