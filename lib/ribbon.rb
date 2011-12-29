require 'ribbon/methods'
require 'ribbon/version'

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

  extend Methods

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

  # Computes a simple key:value string for easy visualization.
  #
  # In +opts+ can be specified several options that customize how the string
  # is generated. Among those options:
  #
  # [:separator]  Used to separate a key/value pair. Default is <tt>': '</tt>.
  # [:key]        Symbol that will be sent to the key in order to obtain its
  #               string representation. Defaults to <tt>:to_s</tt>.
  # [:value]      Symbol that will be sent to the value in order to obtain its
  #               string representation. Defaults to <tt>:inspect</tt>.
  #
  # No matter what is given as the key or value of a
  def to_s(opts = {})
    ksym = opts.fetch(:key,   :to_s).to_sym
    vsym = opts.fetch(:value, :inspect).to_sym
    separator = opts.fetch(:separator, ': ').to_s
    values = ::Ribbon.map(self) do |k, v|
      k = if ::Ribbon.instance? k then k.to_s opts else k.send ksym end
      v = if ::Ribbon.instance? v then v.to_s opts else v.send vsym end
      "#{k}#{separator}#{v}"
    end.join ', '
    "{Ribbon #{values}}"
  end

  # Same as #to_s.
  alias :inspect :to_s

end
