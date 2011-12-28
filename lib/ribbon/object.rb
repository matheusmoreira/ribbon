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

  end

end
