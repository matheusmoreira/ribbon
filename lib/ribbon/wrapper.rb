require 'ribbon'

class Ribbon < BasicObject

  # Wraps around a Ribbon in order to provide general-purpose methods.
  #
  # Ribbons are designed to use methods as hash keys. In order to maximize
  # possibilities, many useful methods were left out of the Ribbon class and
  # implemented in this wrapper class instead.
  #
  # One usually wraps a Ribbon on the fly in order to work with it:
  #
  #   r = Ribbon.new
  #   Ribbon[r].each { |k, v| p [k,v] }
  #
  # If a method the wrapper doesn't respond to is called, it will simply be
  # forwarded to the wrapped Ribbon:
  #
  #   w = Ribbon[r]
  #   w.x = 10
  #   w.ribbon.x
  #   => 10
  class Wrapper

    class << self

      # Wraps a Ribbon instance.
      #
      #   Ribbon::Wrapper[ribbon]
      alias [] new

    end

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
    def initialize(ribbon = Ribbon.new)
      self.ribbon = ribbon
    end

    # Returns the hash of the wrapped Ribbon.
    def hash
      ribbon.__hash__
    end

    # Forwards the method, arguments and block to the wrapped Ribbon's hash, if
    # it responds to the method, or to the ribbon itself otherwise.
    def method_missing(method, *args, &block)
      if hash.respond_to? method then hash
      else ribbon end.__send__ method, *args, &block
    end

    # Wraps all ribbons contained by this wrapper's ribbon.
    def wrap_all!
      wrap_all_recursive!
    end

    # Converts the wrapped Ribbon and all Ribbons inside into hashes.
    def to_hash
      to_hash_recursive
    end

    # Converts the wrapped Ribbon to a hash and serializes it with YAML. To get
    # a Ribbon back from the serialized hash, you can simply load the hash and
    # pass it to the Ribbon constructor:
    #
    #   ribbon = Ribbon.new YAML.load(str)
    def to_yaml
      to_hash.to_yaml
    end

    # Delegates to Ribbon#to_s.
    def to_s
      ribbon.to_s
    end

    private

    # Converts the wrapped Ribbon and all Ribbons inside into hashes using
    # recursion. This implementation avoids the creation of additional Ribbon or
    # Ribbon::Wrapper objects.
    def to_hash_recursive(ribbon = self.ribbon)
      {}.tap do |hash|
        ribbon.__hash__.each do |key, value|
          hash[key] = case value
            when ::Ribbon then to_hash_recursive value
            when ::Ribbon::Wrapper then to_hash_recursive value.ribbon
            else value
          end
        end
      end
    end

    # Recursively wraps all Ribbons inside. This implementation avoids the
    # creation of additional Ribbon or Ribbon::Wrapper objects.
    def wrap_all_recursive!(wrapper = self)
      wrapper.hash.each do |key, value|
        wrapper.hash[key] = case value
          when ::Ribbon then wrap_all_recursive! ::Ribbon::Wrapper[value]
          else value
        end
      end
      wrapper
    end

  end
end
