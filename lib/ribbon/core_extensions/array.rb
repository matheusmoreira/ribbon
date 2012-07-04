require 'ribbon'

class Ribbon
  module CoreExtensions

    # Methods to work with ribbons in arrays.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.6.0
    module Array

      # Extracts the last argument as a ribbon or returns an empty one.
      #
      # @return [Ribbon] the ribbon at the end of this array
      # @see #extract_raw_ribbon
      def extract_ribbon!
        case last
          when Hash, Ribbon::Raw then Ribbon.new pop
          when Ribbon then pop
          else Ribbon.new
        end
      end

      alias extract_options_as_ribbon! extract_ribbon!

      # Extracts the last argument as a raw ribbon or returns an empty one.
      #
      # @return [Ribbon::Raw] the raw ribbon at the end of this array
      # @since 0.8.0
      # @see #extract_ribbon!
      def extract_raw_ribbon!
        Ribbon::Raw.new extract_ribbon!
      end

      alias extract_options_as_raw_ribbon! extract_raw_ribbon!

    end

    ::Array.send :include, ::Ribbon::CoreExtensions::Array

  end
end
