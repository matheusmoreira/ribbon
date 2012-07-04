class Ribbon
  module CoreExtensions

    # Some useful methods.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.6.0
    module BasicObject

      # Evaluates the block using +instance_eval+ if it takes no arguments;
      # yields this object to it otherwise.
      #
      # @yieldparam [self] object this object
      # @return [::Object, nil] the result of the block or nil if not given one
      def __yield_or_eval__(&block)
        if block.arity.zero?
          instance_eval &block
        else
          block.call self
        end unless block.nil?
      end

    end

    ::BasicObject.send :include, ::Ribbon::CoreExtensions::BasicObject

  end
end
