%w(core_ext/basic_object options version wrapper).each do |file|
  require file.prepend 'ribbon/'
end

# == Ruby Object Notation.
#
# ==== Inspired by JSON and OpenStruct.
#
# Ribbons are essentially hashes that use method calls as keys. This is done via
# <tt>method_missing</tt>. On top of that, one may still use it as a
# general-purpose hash, since the <tt>[key]</tt> and <tt>[key] = value</tt>
# methods are defined.
#
# Ribbons support cascading references seamlessly. If you access a property that
# hasn't been set, a new ribbon is created and returned, allowing you to
# continue your calls:
#
#   r = Ribbon.new
#   r.a.b.c = 10
#
# You can also assign properties by passing an argument to the method:
#
#   r.a.b.c 10
#
# If you pass a block, the value will be yielded:
#
#   r.a { |a| a.b { |b| b.c 10 } }
#
# If the block passed takes no arguments, it will be <tt>instance_eval</tt>ed on
# the value instead:
#
#   r.a { b { c 10 } }
#
# Appending a <tt>!</tt> to the end of the property sets the value and returns
# the receiver:
#
#   r.x!(10).y!(20).z!(30)    # Equivalent to: r.x = 10; r.y = 20; r.z = 30
#    => {x: 10, y: 20, z: 30}
#
# Appending a <tt>?</tt> to the end of the property allows you to peek at the
# contents of the property without creating a new ribbon if it is missing:
#
#   r.p?
#    => nil
#
# Seamless reference cascade using arbitrary keys are also supported via the
# <tt>[key]</tt> and <tt>[key] = value</tt> operators, which allow you to
# directly manipulate the internal hash:
#
#   r[:j][:k][:l]
#
# Keep in mind that the <tt>[key]</tt> operator will always create new ribbons
# for missing properties, which is something that may not be desirable; consider
# wrapping the ribbon with a Ribbon::Wrapper in order to have better access to
# the underlying hash.
class Ribbon < BasicObject

  # The hash used internally.
  #
  # @return [Hash] the hash used by this Ribbon instance to store data
  # @api private
  def __hash__
    @hash ||= (::Hash.new &::Ribbon.default_value_proc)
  end

  # Initializes a new ribbon.
  #
  # If given a block, the ribbon will be yielded to it. If the block doesn't
  # take any arguments, it will be evaluated in the context of the ribbon.
  #
  # All objects inside the hash will be converted.
  #
  # @param [Hash, Ribbon, Ribbon::Wrapper] hash the hash with the initial values
  # @see CoreExt::BasicObject#__yield_or_eval__
  # @see convert_all!
  def initialize(hash = {}, &block)
    __hash__.merge! ::Ribbon.extract_hash_from(hash)
    __yield_or_eval__ &block
   ::Ribbon.convert_all! self
  end

  # Fetches the value associated with the given key.
  #
  # If given a block, the value will be yielded to it. If the block doesn't take
  # any arguments, it will be evaluated in the context of the value.
  #
  # @return the value associated with the given key
  # @see CoreExt::BasicObject#__yield_or_eval__
  def [](key, &block)
    value = ::Ribbon.convert __hash__[key]
    value.__yield_or_eval__ &block
    self[key] = value
  end

  # Associates the given values with the given key.
  #
  # @param key the key that will identify the values
  # @param values the values that will be associated with the key
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
    __hash__[key] = if values.size == 1 then values.first else values end
  end

  # Handles the following cases:
  #
  #   ribbon.method                  =>  ribbon[method]
  #   ribbon.method   value          =>  ribbon[method] = value
  #   ribbon.method          &block  =>  ribbon[method, &block]
  #   ribbon.method   value, &block  =>  ribbon[method] = value
  #                                      ribbon[method, &block]
  #
  #   ribbon.method = value          =>  ribbon[method] = value
  #
  #   ribbon.method!  value          =>  ribbon[method] = value
  #                                      self
  #   ribbon.method!         &block  =>  ribbon[method, &block]
  #                                      self
  #   ribbon.method!  value, &block  =>  ribbon[method] = value
  #                                      ribbon[method, &block]
  #                                      self
  #
  #   ribbon.method?                 =>  ribbon.__hash__.fetch method
  #   ribbon.method?  value          =>  ribbon.__hash__.fetch method, value
  #   ribbon.method?         &block  =>  ribbon.__hash__.fetch method, &block
  #   ribbon.method?  value, &block  =>  ribbon.__hash__.fetch method, value, &block
  #
  # @api private
  def method_missing(method, *args, &block)
    method_string = method.to_s
    key = method_string.strip.gsub(/[=?!]$/, '').strip.intern
    case method_string[-1]
      when ?=
        __send__ :[]=, key, *args
      when ?!
        __send__ :[]=, key, *args unless args.empty?
        self[key, &block]
        self
      when ??
        begin self.__hash__.fetch key, *args, &block
        rescue ::KeyError; nil end
      else
        __send__ :[]=, key, *args unless args.empty?
        self[key, &block]
    end
  end

  # Generates a simple <tt>key: value</tt> string representation of this ribbon.
  #
  # @option opts [String] :separator Separates the key/value pair.
  #                                  Default is <tt>': '</tt>.
  # @option opts [Symbol] :key       Will be sent to the key in order to convert
  #                                  it to a string. Default is <tt>:to_s</tt>.
  # @option opts [Symbol] :value     Will be sent to the value in order to
  #                                  convert it to a string. Default is
  #                                  <tt>:inspect</tt>.
  # @return [String] the string representation of this ribbon
  def to_s(opts = {})
    __to_s_recursive__ ::Ribbon.extract_hash_from(opts)
  end

  alias inspect to_s

  private

  # Computes a string value recursively for the given ribbon, and all ribbons
  # inside it, using the given options.
  #
  # @see #to_s
  def __to_s_recursive__(opts = {}, ribbon = self)
    ksym = opts.fetch(:key,   :to_s).to_sym
    vsym = opts.fetch(:value, :inspect).to_sym
    separator = opts.fetch(:separator, ': ').to_s
    values = ribbon.__hash__.map do |k, v|
      k = k.ribbon if ::Ribbon.wrapped? k
      v = v.ribbon if ::Ribbon.wrapped? v
      k = if ::Ribbon.instance? k then __to_s_recursive__ opts, k else k.__send__ ksym end
      v = if ::Ribbon.instance? v then __to_s_recursive__ opts, v else v.__send__ vsym end
      "#{k}#{separator}#{v}"
    end.join ', '
    "{#{values}}"
  end

end

class << Ribbon

  # Proc used to store a new Ribbon instance as the value of a missing key.
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
  # @param [Ribbon, Ribbon::Wrapper] ribbon the ribbon whose values are to be
  #                                         converted
  # @return [Ribbon, Ribbon::Wrapper] the ribbon with all values converted
  # @see convert
  def convert_all!(ribbon)
    ribbon.__hash__.each do |key, value|
      ribbon[key] = case value
        when Ribbon then convert_all! value
        when Ribbon::Wrapper then convert_all! value.ribbon
        else convert value
      end
    end
    ribbon
  end

  # Merges the hashes of the given ribbons.
  #
  # @param [Ribbon, Ribbon::Wrapper, Hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Wrapper, Hash] new_ribbon the ribbon with new values
  # @return [Ribbon] a new ribbon containing the results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @see merge!
  # @see extract_hash_from
  def merge(old_ribbon, new_ribbon, &block)
    old_hash = extract_hash_from old_ribbon
    new_hash = extract_hash_from new_ribbon
    merged_hash = old_hash.merge new_hash, &block
    Ribbon.new merged_hash
  end

  # Merges the hashes of the given ribbons in place.
  #
  # @param [Ribbon, Ribbon::Wrapper, Hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Wrapper, Hash] new_ribbon the ribbon with new values
  # @return [Ribbon, Ribbon::Wrapper, Hash] old_ribbon, which will contain the
  #                                         results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @see merge
  # @see extract_hash_from
  def merge!(old_ribbon, new_ribbon, &block)
    old_hash = extract_hash_from old_ribbon
    new_hash = extract_hash_from new_ribbon
    old_hash.merge! new_hash, &block
    old_ribbon
  end

  # Merges everything inside the given ribbons.
  #
  # @param [Ribbon, Ribbon::Wrapper, Hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Wrapper, Hash] new_ribbon the ribbon with new values
  # @return [Ribbon] a new ribbon containing the results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @see merge
  # @see deep_merge!
  # @see extract_hash_from
  def deep_merge(old_ribbon, new_ribbon, &block)
    deep :merge, old_ribbon, new_ribbon, &block
  end

  # Merges everything inside the given ribbons in place.
  #
  # @param [Ribbon, Ribbon::Wrapper, Hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Wrapper, Hash] new_ribbon the ribbon with new values
  # @return [Ribbon, Ribbon::Wrapper, Hash] old_ribbon, which will contain the
  #                                         results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @see merge!
  # @see deep_merge
  # @see extract_hash_from
  def deep_merge!(old_ribbon, new_ribbon, &block)
    deep :merge!, old_ribbon, new_ribbon, &block
  end

  # Tests whether the given object is an instance of Ribbon.
  #
  # @param object the object to be tested
  # @return [true, false] whether the object is an instance of Ribbon
  def instance?(object)
    Ribbon === object
  end

  # Tests whether the given object is an instance of Ribbon::Wrapper.
  #
  # @param object the object to be tested
  # @return [true, false] whether the object is an instance of Ribbon::Wrapper
  def wrapped?(ribbon)
    Ribbon::Wrapper === ribbon
  end

  # Wraps a ribbon instance in a Ribbon::Wrapper.
  def wrap(ribbon = ::Ribbon.new)
    Ribbon::Wrapper.new ribbon
  end

  # Returns the hash of the given wrapped or unwrapped +ribbon+.
  #
  # Raises ArgumentError if given an unsupported argument.
  def extract_hash_from(parameter)
    case parameter
      when Ribbon::Wrapper then parameter.internal_hash
      when Ribbon then parameter.__hash__
      when Hash then parameter
      else raise ArgumentError, "Couldn't extract hash from #{ribbon.inspect}"
    end
  end

  # Deserializes the hash from the +string+ using YAML and uses it to
  # construct a new ribbon.
  def from_yaml(string)
    Ribbon.new YAML.load(string)
  end

  # Creates a new Ribbon instance.
  #
  #   Ribbon[a: :a, b: :b, c: :c]
  alias [] new

  private

  # Common logic for deep merge methods. +merge_method+ should be either
  # +:merge+ or +:merge!+, and denotes which method will be used to merge
  # recursively. +args+ will be forwarded to the merge method.
  #
  # If given a block, it will be called with the key, the old value and the
  # new value as parameters and its return value will be used. The value of
  # the new hash will be used, otherwise.
  def deep(merge_method, old_ribbon, new_ribbon, &block)
    send merge_method, old_ribbon, new_ribbon do |key, old_value, new_value|
      if instance?(old_value) and instance?(new_value)
        deep merge_method, old_value, new_value, &block
      else
        if block then block.call key, old_value, new_value
        else new_value end
      end
    end
  end

end
