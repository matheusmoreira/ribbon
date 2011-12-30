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
# from BasicObject and doesn't implement any methods. Ribbons are designed to be
# used together with Ribbon::Wrapper, which provides the methods useful for
# computation.
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

end
