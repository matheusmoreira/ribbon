require 'ribbon'

class Ribbon < BasicObject
  module CoreExt

    # Includes methods to convert hashes to ribbons.
    module Hash

      # Converts this hash to a Ribbon.
      def to_ribbon
        Ribbon.new self
      end

      # Converts this hash to a Ribbon::Wrapper.
      def to_ribbon_wrapper
        Ribbon.wrap self
      end

      # Same as #to_ribbon.
      alias to_rbon to_ribbon

      # Same as #to_ribbon_wrapper.
      alias to_wrapped_ribbon to_ribbon_wrapper

    end

    ::Hash.send :include, ::Ribbon::CoreExt::Hash

  end
end
