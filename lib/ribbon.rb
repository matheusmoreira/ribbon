require 'ribbon/version'
require 'ribbon/wrapper'

# Ruby Object Notation.
#
# Inspired by JSON and OpenStruct.
#
# Contains a hash whose keys that are symbols can be accessed via method calls.
# This is done via <tt>method_missing</tt>.
#
# In order to make room for as many method names as possible, Ribbon inherits
# from BasicObject and implements as many methods as possible at the class
# level.
class Ribbon < BasicObject

  # The internal Hash.
  def __hash__
    @hash ||= {}
  end

  # Merges the internal hash with the given one.
  def initialize(hash = {}, &block)
    __hash__.merge! hash, &block
   ::Ribbon.convert_all! self
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
          ::Ribbon.convert self[method]
        else
          ::Ribbon.new
        end
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

  class << self

    # Wraps a Ribbon instance in a Ribbon::Wrapper.
    #
    #   Ribbon[ribbon].keys
    alias [] wrap

  end

end
