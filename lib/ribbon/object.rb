module Ribbon

  # Contains a hash whose keys that are symbols or strings can be accessed via
  # method calls. This is done via <tt>method_missing</tt>.
  #
  # In order to make room for as many method names as possible, Ribbon::Object
  # inherits from BasicObject.
  class Object < BasicObject

    # The internal Hash.
    def __hash__
      @hash ||= {}
    end

    # Merges the internal hash with the given one.
    def initialize(hash = {}, &block)
      __hash__.merge! hash, &block
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
    #   options.method = value  =>  rbon[method] = value
    #   options.method!  value  =>  rbon[method] = value
    #   options.method?         =>  rbon[method] ? true : false
    #   options.method          =>  rbon[method]
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

    def to_s
      values = __hash__.map { |k, v| "#{k}:#{v}" }
      "<Ribbon #{values.join}>"
    end

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

  end

end
