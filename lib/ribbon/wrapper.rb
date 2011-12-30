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

    # Forwards the method, arguments and block to the wrapped Ribbon.
    def method_missing(method, *args, &block)
      ribbon.__send__ method, *args, &block
    end

    # Wraps a Ribbon object, providing many general-purpose methods that were
    # not defined in the Ribbon itself.
    def initialize(ribbon)
      self.ribbon = ribbon
    end

    # Returns the hash of the wrapped Ribbon.
    def hash
      ribbon.__hash__
    end

    # Yields a key => value pair to the given block and returns an array
    # containing the values returned by the block on each iteration.
    def map(&block)
      hash.map &block
    end

    # Returns the hash keys of the wrapped ribbon.
    def keys
      hash.keys
    end

    # Returns the values present in the hash of the wrapped ribbon.
    def values
      hash.values
    end

    # Yields a key => value pair to the given block.
    def each(&block)
      hash.each &block
    end

    # Same as #each.
    alias each_pair each

    # Merges the hash of the wrapped Ribbon with +new+'s.
    def merge!(new, &block)
      hash.merge! new.__hash__, &block
    end

    # Converts the wrapped Ribbon and all Ribbons inside into hashes.
    def to_hash
      {}.tap do |hash|
        each do |key, value|
          hash[key] = case value
            when Ribbon then Wrapper[value].to_hash
            else value
          end
        end
      end
    end

    # Converts the wrapped Ribbon to a hash and serializes it with YAML. To get
    # a ribbon back from the serialized hash, you can simply load the hash and
    # pass it to the Ribbon::Object constructor:
    #
    #   ribbon = Ribbon::Object.new YAML.load(str)
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
        k = if Ribbon.instance? k then to_s_recursive opts, k else k.send ksym end
        v = if Ribbon.instance? v then to_s_recursive opts, v else v.send vsym end
        "#{k}#{separator}#{v}"
      end.join ', '
      "{#{values}}"
    end

  end
end
