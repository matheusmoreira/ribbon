require 'ribbon'

class Ribbon < BasicObject

  # Wraps around a Ribbon in order to provide general-purpose methods.
  #
  # Ribbons are designed to use methods as hash keys. In order to maximize the
  # number of possibilities, many useful methods were left out of the ribbon
  # class and implemented in this wrapper class instead.
  #
  # This class lets you to use ribbons like an ordinary hash. Any undefined
  # methods will be sent to the ribbon's hash. If the hash doesn't respond to
  # the method, it will be sent to the ribbon itself.
  #
  #   wrapper = Ribbon::Wrapper.new
  #
  #   wrapper.a.b.c
  #    => {}
  #   wrapper.keys
  #    => [:a]
  #
  # Keep in mind that the wrapped hash may contain other ribbons, which may not
  # be wrapped:
  #
  #   wrapper.a.b.c.keys
  #    => {}
  #   wrapper
  #    => {a: {b: {c: {keys: {}}}}}
  #
  # You can wrap and unwrap all ribbons inside:
  #
  #   wrapper.wrap_all!
  #   wrapper.unwrap_all!
  class Wrapper

    # The wrapped Ribbon.
    #
    # @return [Ribbon] the ribbon wrapped by this instance
    attr :ribbon

    # @!attribute [w] ribbon
    #
    #   Wraps a Ribbon, another Wrapper's Ribbon or a hash.
    #
    #   @param [Ribbon, Ribbon::Wrapper, #to_hash] ribbon the ribbon to wrap
    #   @return the wrapped Ribbon
    def ribbon=(ribbon)
      @ribbon = case ribbon
        when Wrapper then ribbon.ribbon
        when Ribbon then ribbon
        else Ribbon.new ribbon.to_hash
      end
    end

    # Wraps the given Ribbon, another Wrapper's Ribbon or a hash.
    #
    # If given a block, the wrapper will be yielded to it. If the block doesn't
    # take any arguments, it will be evaluated in the context of the wrapper.
    #
    # @see #ribbon=
    # @see Ribbon#initialize
    def initialize(ribbon = Ribbon.new, &block)
      self.ribbon = ribbon
      __yield_or_eval__ &block
    end

    # The hash used by the wrapped Ribbon.
    #
    # @return [Hash] the internal hash of the Ribbon wrapped by this instance
    def internal_hash
      ribbon.__hash__
    end

    # Forwards the method, arguments and block to the wrapped Ribbon's hash, if
    # it responds to the method, or to the ribbon itself otherwise.
    def method_missing(method, *args, &block)
      if (hash = internal_hash).respond_to? method then hash
      else ribbon end.__send__ method, *args, &block
    end

    # Merges the contents of this wrapped Ribbon with the contents of the given
    # Ribbon into a new Ribbon::Wrapper instance.
    #
    # @param [Ribbon, Ribbon::Wrapper, #to_hash] ribbon the ribbon with new
    #                                                   values
    # @return [Ribbon::Wrapper] a new wrapped ribbon containing the results of
    #                           the merge
    # @yieldparam key the key which identifies both values
    # @yieldparam old_value the value from this wrapped Ribbon
    # @yieldparam new_value the value from the given ribbon
    # @yieldreturn the object that will be used as the new value
    # @see #deep_merge!
    # @see Ribbon.deep_merge
    def deep_merge(ribbon, &block)
      Ribbon.wrap Ribbon.deep_merge(self, ribbon, &block)
    end

    # Merges this wrapped Ribbon with the given Ribbon.
    #
    # @param [Ribbon, Ribbon::Wrapper, #to_hash] ribbon the ribbon with new
    #                                                   values
    # @return [self] this Ribbon::Wrapper instance
    # @yieldparam key the key which identifies both values
    # @yieldparam old_value the value from this wrapped Ribbon
    # @yieldparam new_value the value from the given ribbon
    # @yieldreturn the object that will be used as the new value
    # @see #deep_merge
    # @see Ribbon.deep_merge!
    def deep_merge!(ribbon, &block)
      Ribbon.deep_merge! self, ribbon, &block
    end

    # Wraps all ribbons contained by this wrapper's ribbon.
    def wrap_all!
      wrap_all_recursive!
    end

    # Unwraps all ribbons contained by this wrapper's ribbon.
    def unwrap_all!
      unwrap_all_recursive!
    end

    # Converts the wrapped Ribbon and all ribbons inside into hashes.
    def to_hash
      to_hash_recursive
    end

    # Converts the wrapped ribbon to a hash and serializes it with YAML. To get
    # a Ribbon back from the serialized hash, you can simply load the hash and
    # pass it to the Ribbon constructor:
    #
    #   ribbon = Ribbon.new YAML.load(str)
    #
    # Alternatively, you can pass a YAML string to the Wrapper::from_yaml
    # method.
    def to_yaml
      to_hash.to_yaml
    end

    # Delegates to Ribbon#to_s.
    def to_s
      ribbon.to_s
    end

    private

    # Converts the wrapped ribbon and all ribbons inside into hashes using
    # recursion.
    def to_hash_recursive(ribbon = self.ribbon)
      {}.tap do |hash|
        ribbon.__hash__.each do |key, value|
          hash[key] = case value
            when Ribbon then to_hash_recursive value
            when Ribbon::Wrapper then to_hash_recursive value.ribbon
            else value
          end
        end
      end
    end

    # Recursively wraps all ribbons and hashes inside.
    def wrap_all_recursive!(wrapper = self)
      (hash = wrapper.internal_hash).each do |key, value|
        hash[key] = case value
          when Ribbon, Hash then wrap_all_recursive! Ribbon::Wrapper[value]
          else value
        end
      end
      wrapper
    end

    # Recursively unwraps all wrapped ribbons inside.
    def unwrap_all_recursive!(ribbon = self.ribbon)
      ribbon.__hash__.each do |key, value|
        ribbon[key] = case value
          when Ribbon::Wrapper then unwrap_all_recursive! value.ribbon
          else value
        end
      end
      ribbon
    end

  end

  class << Wrapper

    # Wraps a Ribbon instance.
    #
    #   Ribbon::Wrapper[ribbon]
    alias [] new

    # Deserializes the hash from the +string+ using YAML and uses it to
    # construct a new wrapped ribbon.
    def from_yaml(string)
      ::Ribbon::Wrapper.new YAML.load(string)
    end

  end
end
