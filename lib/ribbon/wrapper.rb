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

    # The wrapped Ribbon object.
    attr :ribbon

    # Wraps +ribbon+. If it is already wrapped, uses the wrapped ribbon as this
    # wrapper's ribbon. If it is a hash, creates a new Ribbon with its data.
    #
    # Raises ArgumentError if given something unsupported.
    def ribbon=(ribbon)
      @ribbon = case ribbon
        when Wrapper then ribbon.ribbon
        when Hash then Ribbon.new ribbon
        when Ribbon then ribbon
        else raise ArgumentError, "Can't wrap #{ribbon.class}"
      end
    end

    # Wraps a Ribbon object, providing many general-purpose methods that were
    # not defined in the Ribbon itself.
    def initialize(ribbon = Ribbon.new, &block)
      self.ribbon = ribbon
      __yield_or_eval__ &block
    end

    # Returns the hash of the wrapped ribbon.
    def internal_hash
      ribbon.__hash__
    end

    # Forwards the method, arguments and block to the wrapped Ribbon's hash, if
    # it responds to the method, or to the ribbon itself otherwise.
    def method_missing(method, *args, &block)
      if (hash = internal_hash).respond_to? method then hash
      else ribbon end.__send__ method, *args, &block
    end

    # Merges the +new_ribbon+ and all nested ribbons with the +old_ribbon+
    # recursively, returning a new ribbon.
    def deep_merge(ribbon)
      Ribbon.wrap Ribbon.deep_merge(self, ribbon)
    end

    # Merges the +new_ribbon+ and all nested ribbons with the +old_ribbon+
    # recursively, modifying all ribbons in place.
    def deep_merge!(ribbon)
      Ribbon.deep_merge! self, ribbon
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

    class << self

      # Wraps a Ribbon instance.
      #
      #   Ribbon::Wrapper[ribbon]
      alias [] new

      # Deserializes the hash from the +string+ using YAML and uses it to
      # construct a new wrapped ribbon.
      def from_yaml(string)
        Ribbon::Wrapper.new YAML.load(string)
      end

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
end
