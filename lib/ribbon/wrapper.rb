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
    attr_accessor :ribbon

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

    # Merges the hash of this wrapped Ribbon with the given +ribbon+, which can
    # be a Ribbon::Wrapper, a Ribbon or a hash.
    #
    # This method returns a new hash.
    def merge(ribbon, &block)
      hash.merge Ribbon.extract_hash_from(ribbon), &block
    end

    # Merges the hash of this wrapped Ribbon with the given +ribbon+, which can
    # be a Ribbon::Wrapper, a Ribbon or a hash.
    #
    # This method modifies the hash of this wrapped Ribbon.
    def merge!(ribbon, &block)
      hash.merge! Ribbon.extract_hash_from(ribbon), &block
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

    # Computes a simple key: value string for easy visualization of the wrapped
    # Ribbon.
    #
    # In +opts+ can be specified several options that customize how the string
    # is generated. Among those options:
    #
    # [:separator]  Used to separate a key/value pair. Default is <tt>': '</tt>.
    # [:key]        Symbol that will be sent to the key in order to obtain its
    #               string representation. Defaults to <tt>:to_s</tt>.
    # [:value]      Symbol that will be sent to the value in order to obtain its
    #               string representation. Defaults to <tt>:inspect</tt>.
    def to_s(opts = {})
      to_s_recursive opts, ribbon
    end

    # Same as #to_s.
    alias :inspect :to_s

    private

    # Computes a string value recursively for the given Ribbon and all Ribbons
    # inside it. This implementation avoids creating additional Ribbon or
    # Ribbon::Wrapper objects.
    def to_s_recursive(opts, ribbon)
      ksym = opts.fetch(:key,   :to_s).to_sym
      vsym = opts.fetch(:value, :inspect).to_sym
      separator = opts.fetch(:separator, ': ').to_s
      values = ribbon.__hash__.map do |k, v|
        k = k.ribbon if Ribbon.wrapped? k
        v = v.ribbon if Ribbon.wrapped? v
        k = if Ribbon.instance? k then to_s_recursive opts, k else k.send ksym end
        v = if Ribbon.instance? v then to_s_recursive opts, v else v.send vsym end
        "#{k}#{separator}#{v}"
      end.join ', '
      "{#{values}}"
    end

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

  end
end
