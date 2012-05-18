require 'ribbon'
require 'ribbon/core_ext/array'

class Ribbon < BasicObject

  # Applies options to all method calls.
  #
  #   Ribbon::Options.new(object, option: :value) do
  #     method_with some: :settings  # equivalent to { some: :settings, option: :value }
  #     override option: :another_value
  #   end
  #
  #   Ribbon::Options.apply_to(Ribbon.new, separator: '->') do |ribbon|
  #     ribbon.to_s
  #     ribbon.inspect
  #   end
  class Options < BasicObject

    # Applies the given options to all methods sent to the receiver.
    #
    # Will #apply the block immediately, if given one.
    def initialize(receiver, options = {}, &block)
      @receiver, @options = receiver, options
      apply &block
    end

    # @see CoreExt::BasicObject.__yield_or_eval__
    def apply(&block)
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

    # Same as #new.
    alias apply_to new

  end

end
