class Ribbon < BasicObject
  module CoreExt

    # Some useful methods.
    module BasicObject

      # Evaluates the block using +instance_eval+ if it takes no arguments;
      # yields +self+ to it otherwise.
      def __yield_or_eval__(&block)
        if block.arity.zero? then instance_eval &block else block.call self end if block
      end

    end

    ::BasicObject.send :include, ::Ribbon::CoreExt::BasicObject

  end
end
