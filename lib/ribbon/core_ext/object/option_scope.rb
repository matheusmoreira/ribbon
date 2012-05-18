require 'ribbon/options'

class Ribbon < BasicObject
  module CoreExt

    module Object

      # Applies an option scope to this object, where all methods called in the
      # block receive the specified options.
      #
      # @see Ribbon::Options
      def option_scope(options = {}, &block)
        Ribbon::Options.apply_to self, options, &block
      end

    end

    ::Object.send :include, ::Ribbon::CoreExt::Object

  end
end
