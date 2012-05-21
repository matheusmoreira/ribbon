%w(core_extensions/basic_object options version wrapper).each do |file|
  require file.prepend 'ribbon/'
end

# Ribbons are essentially hashes that use method names as keys.
#
#   r = Ribbon.new
#   r.key = :value
#
# If you access a property that hasn't been set, a new ribbon will be returned.
# This allows you to easily work with nested structures:
#
#   r.a.b.c = 10
#
# You can also assign properties by passing an argument to the method:
#
#   r.a.b.c 20
#
# If you pass a block, the value will be yielded:
#
#   r.a do |a|
#     a.b do |b|
#       b.c 30
#     end
#   end
#
# If the block passed takes no arguments, it will be <tt>instance_eval</tt>uated
# in the context of the value instead:
#
#   r.a do
#     b do
#       c 40
#     end
#   end
#
# Appending a bang (<tt>!</tt>) to the end of the property sets the value and
# returns the receiver:
#
#   Ribbon.new.x!(10).y!(20).z!(30)
#    => {x: 10, y: 20, z: 30}
#
# Appending a question mark (<tt>?</tt>) to the end of the property returns the
# contents of the property without creating a new ribbon if it is missing:
#
#   r.unknown_property?
#    => nil
#
# You can use any object as key with the <tt>[]</tt> and <tt>[]=</tt> operators:
#
#   r['/some/path'].entries = []
#
# @author Matheus Afonso Martins Moreira
# @see Ribbon::Wrapper
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
  # @param [#to_hash, Ribbon, Ribbon::Wrapper] hash the hash with the initial
  #                                                 values
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
  # @param key the key which identifies the value
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

  alias [] new

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
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] old_ribbon the ribbon with old
  #                                                       values
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] new_ribbon the ribbon with new
  #                                                       values
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
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] old_ribbon the ribbon with old
  #                                                       values
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] new_ribbon the ribbon with new
  #                                                       values
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
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] old_ribbon the ribbon with old
  #                                                       values
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] new_ribbon the ribbon with new
  #                                                       values
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
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] old_ribbon the ribbon with old
  #                                                       values
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] new_ribbon the ribbon with new
  #                                                       values
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

  # Tests whether the given object is an instance of {Ribbon::Wrapper}.
  #
  # @param object the object to be tested
  # @return [true, false] whether the object is an instance of {Ribbon::Wrapper}
  def wrapped?(ribbon)
    Ribbon::Wrapper === ribbon
  end

  # Wraps an object in a {Ribbon::Wrapper}.
  #
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] object the object to be wrapped
  # @return [Ribbon::Wrapper] a new wrapped ribbon
  def wrap(object = ::Ribbon.new)
    Ribbon::Wrapper.new object
  end

  # Returns the hash of a Ribbon. Will attempt to convert other objects.
  #
  # @param [Ribbon, Ribbon::Wrapper, #to_hash] parameter the object to convert
  # @return [Hash] the resulting hash
  def extract_hash_from(parameter)
    case parameter
      when Ribbon::Wrapper then parameter.internal_hash
      when Ribbon then parameter.__hash__
      else parameter.to_hash
    end
  end

  # Deserializes the hash from the string using YAML and uses it to construct a
  # new ribbon.
  #
  # @param [String] string a valid YAML string
  # @return [Ribbon] a new Ribbon
  def from_yaml(string)
    Ribbon.new YAML.load(string)
  end

  private

  # Common logic for deep merge methods. +merge_method+ should be either
  # +:merge+ or +:merge!+, and denotes which method will be used to merge
  # recursively.
  #
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @see merge!
  # @see merge
  # @see deep_merge
  # @see deep_merge!
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
