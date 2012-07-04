%w(

ribbon
ribbon/core_extensions/basic_object

).each { |file| require file }

class Ribbon

  # Ribbon with the least amount of helper methods defined.
  #
  # @author Matheus Afonso Martins Moreira
  # @since 0.8.0
  # @see Ribbon
  class Raw < BasicObject

    # The hash used internally.
    #
    # @return [Hash] the hash used by this Ribbon instance to store data
    # @api private
    def __hash__
      @hash ||= (::Hash.new &::Ribbon::Raw.default_value_proc)
    end

    # Initializes a new raw ribbon with the given values.
    #
    # If given a block, the raw ribbon will be yielded to it. If the block
    # doesn't take any arguments, it will be evaluated in the context of the raw
    # ribbon.
    #
    # All objects inside the hash will be {convert_all! converted}.
    #
    # @param [Ribbon, Ribbon::Raw, #to_hash] hash the hash with initial values
    # @see CoreExtensions::BasicObject#__yield_or_eval__
    def initialize(hash = {}, &block)
      __hash__.merge! ::Ribbon.extract_hash_from hash
      __yield_or_eval__ &block
     ::Ribbon::Raw.convert_all! self
    end

    # Fetches the value associated with the given key.
    #
    # If given a block, the value will be yielded to it. If the block doesn't take
    # any arguments, it will be evaluated in the context of the value.
    #
    # @param key the key which identifies the value
    # @return the value associated with the given key
    # @see CoreExtensions::BasicObject#__yield_or_eval__
    def [](key, &block)
      value = ::Ribbon::Raw.convert __hash__[key]
      value.__yield_or_eval__ &block
      self[key] = value
    end

    # Associates the given values with the given key.
    #
    # @param key the key that will identify the values
    # @param values the values that will be associated with the key
    # @raise [ArgumentError] if the given key is a raw ribbon
    # @example
    #   ribbon = Ribbon.new
    #
    #   ribbon[:key] = :value
    #   ribbon[:key]
    #   # => :value
    #
    #   ribbon[:key] = :multiple, :values
    #   ribbon[:key]
    #   # => [:multiple, :values]
    def []=(key, *values)
      raise ArgumentError, 'Raw Ribbons can not be used as hash keys' if ::Ribbon.raw? key
      __hash__[key] = if values.size == 1 then values.first else values end
    end

    # Handles the following cases:
    #
    #   ribbon.method                  =>  ribbon[:method]
    #   ribbon.method   value          =>  ribbon[:method] = value
    #   ribbon.method          &block  =>  ribbon[:method, &block]
    #   ribbon.method   value, &block  =>  ribbon[:method] = value
    #                                      ribbon[:method, &block]
    #
    #   ribbon.method = value          =>  ribbon[:method] = value
    #
    #   ribbon.method!  value          =>  ribbon[:method] = value
    #                                      self
    #   ribbon.method!         &block  =>  block.call ribbon[:method] if ribbon.__hash__.include? :method
    #                                      self
    #   ribbon.method!  value, &block  =>  ribbon[:method] = value
    #                                      block.call ribbon[:method]
    #                                      self
    #
    #   ribbon.method?                 =>  ribbon.__hash__.fetch :method
    #   ribbon.method?  value          =>  ribbon.__hash__.fetch :method, value
    #   ribbon.method?         &block  =>  ribbon.__hash__.fetch :method, &block
    #   ribbon.method?  value, &block  =>  ribbon.__hash__.fetch :method, value, &block
    def method_missing(method, *arguments, &block)
      method_name = method.to_s
      key = method_name.strip.gsub(/[=?!]$/, '').strip.intern
      case method_name[-1]
        when ?=
          __send__ :[]=, key, *arguments
        when ?!
          __send__ :[]=, key, *arguments unless arguments.empty?
          block.call self[key] if block and __hash__.include? key
          self
        when ??
          begin __hash__.fetch key, *arguments, &block
          rescue ::KeyError; nil end
        else
          __send__ :[]=, key, *arguments unless arguments.empty?
          self[key, &block]
      end
    end

    # Generates a simple and customizable human-readable string representation
    # of this raw ribbon.
    #
    # @option options [#to_s] :separator (': ') separates the key/value pair
    # @option options [#to_sym] :key (:to_s) will be sent to the key in order to
    #   convert it to a string.
    # @option options [#to_sym] :value (:inspect) will be sent to the value in
    #   order to convert it to a string.
    # @return [String] the string representation of this raw ribbon
    def to_s(options = {})
      __to_s_recursive__ ::Ribbon.extract_hash_from(options)
    end

    alias inspect to_s

    private

    # Computes a string value recursively for the given ribbon, and all ribbons
    # inside it, using the given options.
    #
    # @see #to_s
    def __to_s_recursive__(options = {}, ribbon = self)
      ksym = options.fetch(:key,   :to_s).to_sym
      vsym = options.fetch(:value, :inspect).to_sym
      separator = options.fetch(:separator, ': ').to_s
      '{%s}' % ribbon.__hash__.map do |k, v|
        k = k.__send__ ksym
        v = v.raw if ::Ribbon === v
        v = if ::Ribbon.raw? v then __to_s_recursive__ options, v
        else v.__send__ vsym end
        '%s%s%s' % [ k, separator, v ]
      end.join(', ')
    end

  end

end

class << Ribbon::Raw

  alias [] new

  # Proc used to store a new {Ribbon ribbon} instance as the value of a missing
  # key.
  #
  # @return [Proc] the proc used when constructing new hashes
  def default_value_proc
    @default_value_proc ||= (proc { |hash, key| hash[key] = Ribbon.new })
  end

  # Converts hashes to ribbons. Will look inside arrays.
  #
  # @param object the object to convert
  # @return the converted value
  def convert(object)
    case object
      when Hash then Ribbon.new object
      when Array then object.map { |element| convert element }
      else object
    end
  end

  # Converts all values inside the given ribbon.
  #
  # @param [Ribbon, Ribbon::Raw] ribbon the ribbon whose values are to be
  #   converted
  # @return [Ribbon, Ribbon::Raw] the ribbon with all values converted
  # @see convert
  def convert_all!(ribbon)
    ribbon.__hash__.each do |key, value|
      ribbon[key] = case value
        when Ribbon then convert_all! value.raw
        when Ribbon::Raw then convert_all! value
        else convert value
      end
    end
    ribbon
  end

end
