%w(

ribbon
ribbon/core_extensions/array

).each { |file| require file }

class Ribbon

  # Applies options to all method calls.
  #
  #   Ribbon::Options.new(object, option: :value) do
  #     method_with some: :settings  # equivalent to { some: :settings, option: :value }
  #     overrides option: { with: :another_value }
  #   end
  #
  #   Ribbon::Options.apply_to(Ribbon.new, separator: '->') do |ribbon|
  #     ribbon.to_s
  #     ribbon.inspect
  #   end
  #
  # @author Matheus Afonso Martins Moreira
  # @since 0.6.0
  class Options < BasicObject

    # Applies the given options to all methods sent to the receiver. Will apply
    # the block immediately, if given one.
    #
    # @param receiver the object that will be receiving the methods
    # @param [Ribbon, Ribbon::Wrapper, #to_hash] options the options that will
    #                                                    be applied to all
    #                                                    methods
    # @see CoreExt::BasicObject#__yield_or_eval__
    def initialize(receiver, options = {}, &block)
      @receiver, @options = receiver, options
      __yield_or_eval__ &block
    end

    # Merges the options given to the method with the options associated with
    # this instance and sends the method to the receiver as normal.
    def method_missing(method, *arguments, &block)
      options = arguments.extract_options_as_ribbon!
      arguments << ::Ribbon.deep_merge(@options, options)
      @receiver.__send__ method, *arguments, &block
    end

  end

  class << Options

    # Applies options to all method calls.
    #
    # @see #initialize
    alias apply_to new

  end

end
