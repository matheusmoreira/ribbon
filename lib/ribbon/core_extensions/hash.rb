require 'ribbon'

class Ribbon
  module CoreExtensions

    # Includes methods to convert hashes to ribbons.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.6.0
    module Hash

      # Converts this hash to a ribbon.
      #
      # @return [Ribbon] a new ribbon with the contents of this hash
      def to_ribbon
        Ribbon.new self
      end

      alias to_rbon to_ribbon

      # Converts this hash to a raw ribbon.
      #
      # @return [Ribbon::Raw] a new raw ribbon with the contents of this hash
      # @since 0.8.0
      def to_raw_ribbon
        Ribbon.wrap self
      end

    end

    ::Hash.send :include, ::Ribbon::CoreExtensions::Hash

  end
end
