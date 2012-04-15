require 'ribbon/version'
require 'ribbon/wrapper'

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

  # The internal Hash.
  def __hash__
    @hash ||= (::Hash.new &::Ribbon.default_value_proc)
  end

  # Initializes the new ribbon, merging the internal hash with the given one and
  # converting all internal objects. See Ribbon::convert_all! for details.
  def initialize(hash = {}, &block)
    __hash__.merge! hash
    if block.arity.zero? then instance_eval &block else block.call self end if block
   ::Ribbon.convert_all! self
  end

  # Gets a value by key.
  def [](key, &block)
    value = ::Ribbon.convert __hash__[key]
    if block.arity.zero? then value.instance_eval &block
    else block.call value end if block
    self[key] = value
  end

  # Sets a value by key.
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
  #   ribbon.method!         &block  =>  TODO
  #   ribbon.method!  value, &block  =>  TODO
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
        __send__ :[]=, key, *args
        self
      when ??
        begin self.__hash__.fetch key, *args, &block
        rescue ::KeyError; nil end
      else
        __send__ :[]=, key, *args unless args.empty?
        self[key, &block]
    end
  end

  # Computes a simple key: value string for easy visualization of this ribbon.
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
    to_s_recursive opts
  end

  # Same as #to_s.
  alias inspect to_s

  # The class methods.
  class << self

    # A Proc which returns a new ribbon as the default value for the given hash
    # key.
    def default_value_proc
      @default_value_proc ||= (proc { |hash, key| hash[key] = Ribbon.new })
    end

    # If <tt>object</tt> is a hash, converts it to a ribbon. If it is an array,
    # converts any hashes inside.
    def convert(object)
      case object
        when Hash then Ribbon.new object
        when Array then object.map { |element| convert element }
        else object
      end
    end

    # Converts all values in the given ribbon.
    def convert_all!(ribbon)
      ribbon.__hash__.each do |key, value|
        ribbon[key] = case value
          when Ribbon then convert_all! value
          else convert value
        end
      end
      ribbon
    end

    # Merges the hash of +new_ribbon+ with the hash of +old_ribbon+, creating a
    # new ribbon in the process.
    def merge(old_ribbon, new_ribbon, &block)
      old_hash = extract_hash_from old_ribbon
      new_hash = extract_hash_from new_ribbon
      merged_hash = old_hash.merge new_hash, &block
      Ribbon.new merged_hash
    end

    # Merges the hash of +new_ribbon+ with the hash of +old_ribbon+, modifying
    # +old_ribbon+'s hash in the process.
    def merge!(old_ribbon, new_ribbon, &block)
      old_hash = extract_hash_from old_ribbon
      new_hash = extract_hash_from new_ribbon
      old_hash.merge! new_hash, &block
      old_ribbon
    end

    # Merges the +new_ribbon+ and all nested ribbons with the +old_ribbon+
    # recursively, returning a new ribbon.
    def deep_merge(old_ribbon, new_ribbon, &block)
      deep :merge, old_ribbon, new_ribbon, &block
    end

    # Merges the +new_ribbon+ and all nested ribbons with the +old_ribbon+
    # recursively, modifying all ribbons in place.
    def deep_merge!(old_ribbon, new_ribbon, &block)
      deep :merge!, old_ribbon, new_ribbon, &block
    end

    # Returns +true+ if the given +object+ is a ribbon.
    def instance?(object)
      Ribbon === object
    end

    # Returns +true+ if the given ribbon is wrapped.
    def wrapped?(ribbon)
      Ribbon::Wrapper === ribbon
    end

    # Wraps a ribbon instance in a Ribbon::Wrapper.
    def wrap(ribbon = ::Ribbon.new)
      Ribbon::Wrapper.new ribbon
    end

    # Unwraps the +ribbon+ if it is wrapped and returns its hash. Returns +nil+
    # in any other case.
    def extract_hash_from(ribbon)
      case ribbon
        when Ribbon::Wrapper then ribbon.internal_hash
        when Ribbon then ribbon.__hash__
        when Hash then ribbon
        else nil
      end
    end

    # Deserializes the hash from the +string+ using YAML and uses it to
    # construct a new ribbon.
    def from_yaml(string)
      Ribbon.new YAML.load(string)
    end

    # Creates a new instance.
    #
    #   Ribbon[a: :a, b: :b, c: :c]
    alias [] new

    private

    # Common logic for deep merge functions. +merge_func+ should be either
    # +merge+ or +merge!+, and denotes which function will be used to merge
    # recursively. +args+ will be forwarded to the merge function.
    #
    # If given a block, it will be called with the key, the old value and the
    # new value as parameters and its return value will be used. The value of
    # the new hash will be used, otherwise.
    def deep(merge_method, old_ribbon, new_ribbon, &block)
      send merge_method, old_ribbon, new_ribbon do |key, old_value, new_value|
        if instance?(old_value) and instance?(new_value)
          deep merge_method, old_value, new_value, &block
        else
          if block.respond_to? :call then block.call key, old_value, new_value
          else new_value end
        end
      end
    end

  end

  private

  # Computes a string value recursively for the given ribbon and all ribbons
  # inside it. This implementation avoids creating additional ribbon or
  # Ribbon::Wrapper objects.
  def to_s_recursive(opts, ribbon = self)
    ksym = opts.fetch(:key,   :to_s).to_sym
    vsym = opts.fetch(:value, :inspect).to_sym
    separator = opts.fetch(:separator, ': ').to_s
    values = ribbon.__hash__.map do |k, v|
      k = k.ribbon if ::Ribbon.wrapped? k
      v = v.ribbon if ::Ribbon.wrapped? v
      k = if ::Ribbon.instance? k then to_s_recursive opts, k else k.send ksym end
      v = if ::Ribbon.instance? v then to_s_recursive opts, v else v.send vsym end
      "#{k}#{separator}#{v}"
    end.join ', '
    "{#{values}}"
  end

end
