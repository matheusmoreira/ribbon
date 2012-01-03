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

    end

    ::Array.send :include, ::Ribbon::CoreExt::Array

  end
end
