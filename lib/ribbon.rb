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
# In order to make room for as many method names as possible, Ribbon inherits
# from BasicObject and doesn't implement any methods. In order to gain access
# to general-purpose computation methods, wrap the ribbon with Ribbon::Wrapper.
class Ribbon < BasicObject

  # The internal Hash.
  def __hash__
    @hash ||= {}
  end

  # Initializes the new Ribbon, merging the internal hash with the given one and
  # converting all internal objects. See Ribbon::convert_all! for details.
  def initialize(hash = {}, &block)
    __hash__.merge! hash, &block
   ::Ribbon.convert_all! self
  end

  # Gets a value by key.
  def [](key)
    __hash__[key] = if __hash__.has_key? key
      ::Ribbon.convert __hash__[key]
    else
      ::Ribbon.new
    end
  end

  # Sets a value by key.
  def []=(key, value)
    __hash__[key] = value
  end

  # Handles the following cases:
  #
  #   ribbon.method          =>  ribbon[method]
  #   ribbon.method = value  =>  ribbon[method] = value
  #   ribbon.method!  value  =>  ribbon[method] = value; self
  #   ribbon.method?         =>  ribbon.__hash__[method] ? true : false
  def method_missing(method, *args, &block)
    m = method.to_s.strip.gsub(/[=?!]$/, '').strip.to_sym
    case method.to_s[-1]
      when '='
        self[m] = args.first
      when '!'
        self[m] = args.first; self
      when '?'
        self.__hash__[m]
      else
        self[method]
    end
  end

  # If <tt>object</tt> is a Hash, converts it to a Ribbon. If it is an Array,
  # converts any hashes inside.
  def self.convert(object)
    case object
      when ::Hash then self.new object
      when ::Array then object.map { |element| convert element }
      else object
    end
  end

  # Converts all values in the given Ribbon.
  def self.convert_all!(ribbon)
    ribbon.__hash__.each do |key, value|
      ribbon[key] = case value
        when self then convert_all! value
        else convert value
      end
    end
    ribbon
  end

  # Computes a simple key: value string for easy visualization of this Ribbon.
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

  # Merges the hash of +new+ with the hash of +old+, creating a new ribbon in
  # the process.
  def self.merge(old, new, &block)
    new extract_hash_from(old).merge(extract_hash_from(ribbon), &block)
  end

  # Merges the hash of +new+ with the hash of +old+, modifying +old+'s hash in
  # the process.
  def self.merge!(old, new, &block)
    extract_hash_from(old).merge! extract_hash_from(ribbon), &block
  end

  # Returns +true+ if the given +object+ is a Ribbon.
  def self.instance?(object)
    self === object
  end

  # Returns +true+ if the given Ribbon is wrapped.
  def self.wrapped?(ribbon)
    Wrapper === ribbon
  end

  # Wraps a Ribbon instance in a Ribbon::Wrapper.
  def self.wrap(ribbon)
    Wrapper.new ribbon
  end

  # Unwraps the +ribbon+ if it is wrapped and returns its hash. Returns nil in
  # any other case.
  def self.extract_hash_from(ribbon)
    ribbon = ribbon.ribbon if ::Ribbon.wrapped? ribbon
    ribbon = ribbon.__hash__ if ::Ribbon.instance? ribbon
  end

  class << self

    # Wraps a Ribbon instance in a Ribbon::Wrapper.
    #
    #   Ribbon[ribbon].keys
    alias [] wrap

  end

  private

  # Computes a string value recursively for the given Ribbon and all Ribbons
  # inside it. This implementation avoids creating additional Ribbon or
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
