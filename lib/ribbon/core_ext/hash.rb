require 'ribbon/object'

module Ribbon
  module CoreExt

    # Includes a method to convert hashes to ribbons.
    module Hash

      # Converts this hash to a Ribbon::Object.
      def to_ribbon
        ::Ribbon::Object.new self
      end

      # Same as #to_ribbon.
      alias to_rbon to_ribbon

    end

    class ::Hash; include ::Ribbon::CoreExt::Hash; end

  end
end
