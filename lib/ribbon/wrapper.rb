require 'ribbon'

class Ribbon < BasicObject

  # Wraps around a Ribbon in order to provide general-purpose methods.
  #
  # Ribbons are designed to use methods as hash keys. In order to maximize
  # possibilities, many useful methods were left out of the ribbon class and
  # implemented in this wrapper class instead.
  #
  # This class enables you to use ribbons like an ordinary hash. Any undefined
  # methods called on a wrapped ribbon will be sent to its hash, or to the
  # ribbon itself if the hash doesn't respond to the method.
  #
  #   r = Ribbon.new
  #   w = Ribbon::Wrapper.new r
  #
  #   w.a.b.c
  #   w[:a][:b][:c]
  #
  # Wrapped ribbons talk directly to their ribbon's hash:
  #
  #   w[:k]
  #   => nil
  #
  # However, keep in mind that the wrapped hash may contain other ribbons,
  # which may not be wrapped:
  #
  #   w.a.b.c[:d]
  #   => {}
  #
  # You can automatically wrap and unwrap all ribbons inside the wrapped one:
  #
  #   w.wrap_all!
  #   w.unwrap_all!
  #
  # The wrapped ribbon receives all undefined methods that hashes won't take:
  #
  #   w.x = 10
  #   w.ribbon.x
  #   => 10
  class Wrapper

    # The wrapped Ribbon object.
    attr :ribbon

    # Wraps +ribbon+. If it is already wrapped, uses the wrapped ribbon as this
    # wrapper's ribbon. If it is a hash, creates a new Ribbon with its data. If
    # it is something else, an ArgumentError will be raised.
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
      if block.arity.zero? then instance_eval &block else block.call self end if block
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

    def deep_merge(ribbon)
      Ribbon.deep_merge self, ribbon
    end

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
    # recursion. This implementation avoids the creation of additional ribbon or
    # wrapper objects.
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

    # Recursively wraps all ribbons and hashes inside. This implementation
    # avoids the creation of additional ribbon or wrapper objects.
    def wrap_all_recursive!(wrapper = self)
      (hash = wrapper.internal_hash).each do |key, value|
        hash[key] = case value
          when Ribbon, Hash then wrap_all_recursive! Ribbon::Wrapper[value]
          else value
        end
      end
      wrapper
    end

    # Recursively unwraps all wrapped ribbons inside. This implementation avoids
    # the creation of additional ribbon or wrapper objects.
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
