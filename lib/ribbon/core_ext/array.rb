require 'ribbon'

class Ribbon < BasicObject
  module CoreExt

    # Methods to work with ribbons in arrays.
    module Array

      # If the last argument is a hash, removes and converts it to a ribbon,
      # otherwise returns an empty ribbon.
      def extract_options_as_ribbon!
        ::Ribbon.new last.is_a?(Hash) ? pop : {}
      end

    end

    ::Array.send :include, ::Ribbon::CoreExt::Array

  end
end
