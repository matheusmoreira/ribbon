require 'ribbon'

class Ribbon < BasicObject
  module CoreExtensions

    # Includes methods to convert hashes to ribbons.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.6.0
    module Hash

      # Converts this hash to a Ribbon.
      #
      # @return a new Ribbon with the contents of this hash
      def to_ribbon
        Ribbon.new self
      end

      # Converts this hash to a Ribbon::Wrapper.
      #
      # @return a new wrapped Ribbon with the contents of this hash
      def to_ribbon_wrapper
        Ribbon.wrap self
      end

      # Same as #to_ribbon.
      #
      # @return a new Ribbon with the contents of this hash
      alias to_rbon to_ribbon

      # Same as #to_ribbon_wrapper.
      #
      # @return a new wrapped Ribbon with the contents of this hash
      alias to_wrapped_ribbon to_ribbon_wrapper

    end

    ::Hash.send :include, ::Ribbon::CoreExtensions::Hash

  end
end
