require 'ribbon'

class Ribbon < BasicObject
  module CoreExtensions

    # Methods to work with ribbons in arrays.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.6.0
    module Array

      # If the last argument is a hash, removes and converts it to a ribbon,
      # otherwise returns an empty ribbon.
      #
      # @return [Ribbon] the Ribbon at the end of this array
      def extract_ribbon!
        case last
          when Hash then Ribbon.new pop
          when Ribbon then pop
          when Ribbon::Wrapper then pop.ribbon
          else Ribbon.new
        end
      end

      # Extracts the last argument as a wrapped ribbon, or returns an empty one.
      # See #extract_ribbon! for details.
      #
      # @return [Ribbon::Wrapper] the wrapped Ribbon at the end of this array
      def extract_wrapped_ribbon!
        Ribbon.wrap extract_ribbon!
      end

      # Same as #extract_ribbon!
      #
      #
      # @return [Ribbon] the Ribbon at the end of this array
      alias extract_options_as_ribbon! extract_ribbon!

      # Same as #extract_wrapped_ribbon!
      #
      # @return [Ribbon::Wrapper] the wrapped Ribbon at the end of this array
      alias extract_options_as_wrapped_ribbon! extract_wrapped_ribbon!

    end

    ::Array.send :include, ::Ribbon::CoreExtensions::Array

  end
end
