require 'ribbon'

class Ribbon < BasicObject
  module CoreExt

    # Methods to work with ribbons in arrays.
    module Array

      # If the last argument is a hash, removes and converts it to a ribbon,
      # otherwise returns an empty ribbon.
      def extract_ribbon!
        case last
          when ::Hash then Ribbon.new pop
          when ::Ribbon then pop
          when ::Ribbon::Wrapper then pop.ribbon
          else Ribbon.new
        end
      end

      # Extracts the last argument as a wrapped ribbon, or returns an empty one.
      # See #extract_ribbon! for details.
      def extract_wrapped_ribbon!
        ::Ribbon.wrap extract_options_as_ribbon!
      end

      alias extract_options_as_ribbon! extract_ribbon!
      alias extract_options_as_wrapped_ribbon! extract_wrapped_ribbon!

    end

    ::Array.send :include, ::Ribbon::CoreExt::Array

  end
end
