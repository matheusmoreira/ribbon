module Ribbon

  # Contains a hash whose keys that are symbols or strings can be accessed via
  # method calls. This is done via <tt>method_missing</tt>.
  #
  # In order to make room for as many method names as possible, Ribbon::Object
  # inherits from BasicObject and implements as many methods as possible at the
  # class level.
  class Object < BasicObject

    # The internal Hash.
    def __hash__
      @hash ||= {}
    end

    # Merges the internal hash with the given one.
    def initialize(hash = {}, &block)
      __hash__.merge! hash, &block
      ::Ribbon::Object.convert_all! self
    end

    # Gets a value by key.
    def [](key)
      __hash__[key]
    end

    # Sets a value by key.
    def []=(key, value)
      __hash__[key] = value
    end

    # Handles the following cases:
    #
    #   ribbon.method = value  =>  ribbon[method] = value
    #   ribbon.method!  value  =>  ribbon[method] = value
    #   ribbon.method?         =>  ribbon[method] ? true : false
    #   ribbon.method          =>  ribbon[method]
    def method_missing(method, *args, &block)
      m = method.to_s.strip.chop.strip.to_sym
      case method.to_s[-1]
        when '=', '!'
          self[m] = args.first
        when '?'
          self[m] ? true : false
        else
          self[method] = if __hash__.has_key? method
            ::Ribbon::Object.convert self[method]
          else
            ::Ribbon::Object.new
          end
      end
    end

    # Computes a simple key:value string for easy visualization.
    #
    # If given a block, yields the key and value and the value returned from the
    # block will be used as the string. The block will also be passed to any
    # internal Ribbon::Object instances.
    def to_s(&block)
      values = __hash__.map do |key, value|
        value = value.to_s &block if ::Ribbon::Object === value
        block ? block.call(key, value) : "#{key.to_s}: #{value.inspect}"
      end
      "{ Ribbon #{values.join ', '} }"
    end

    # Same as #to_s.
    alias :inspect :to_s

    # If <tt>object</tt> is a Hash, converts it to a Ribbon::Object. If it is
    # an Array, converts any hashes inside.
    def self.convert(object)
      case object
        when ::Hash then self.new object
        when ::Array then object.map { |element| convert element }
        else object
      end
    end

    # Converts all values in the given ribbon.
    def self.convert_all!(ribbon)
      each(ribbon) do |key, value|
        ribbon[key] = case value
          when ::Ribbon::Object then convert_all! value
          else convert value
        end
      end
      ribbon
    end

    # Converts +ribbon+ and all Ribbons inside into hashes.
    def self.to_hash(ribbon)
      {}.tap do |hash|
        each(ribbon) do |key, value|
          hash[key] = case value
            when ::Ribbon::Object then to_hash value
            else value
          end
        end
      end
    end

    # Merges +old+'s hash with +new+'s. This is equivalent to calling
    # <tt>merge!</tt> on +old+'s hash and passing it +new+'s hash and the given
    # block.
    def self.merge!(old, new, &block)
      old_hash, new_hash = old.__hash__, new.__hash__
      old_hash.merge! new_hash, &block
    end

    # Returns the hash keys of the given ribbon.
    def self.keys(ribbon)
      ribbon.__hash__.keys
    end

    # Yields a key, value pair to the given block.
    def self.each(ribbon, &block)
      ribbon.__hash__.each &block
    end

  end

end
