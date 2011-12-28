require 'ribbon/object'

module Ribbon

  # Methods that operate on Ribbons. These should be included at the class level
  # in order to keep as many names available for use with ribbons as possible.
  module Methods

    # Returns the hash keys of the given ribbon.
    def keys(ribbon)
      ribbon.__hash__.keys
    end

    # Yields a key, value pair to the given block.
    def each(ribbon, &block)
      ribbon.__hash__.each &block
    end

    # Merges +old+'s hash with +new+'s. This is equivalent to calling
    # <tt>merge!</tt> on +old+'s hash and passing it +new+'s hash and the given
    # block.
    def merge!(old, new, &block)
      old_hash, new_hash = old.__hash__, new.__hash__
      old_hash.merge! new_hash, &block
    end

    # Converts +ribbon+ and all Ribbons inside into hashes.
    def to_hash(ribbon)
      {}.tap do |hash|
        each(ribbon) do |key, value|
          hash[key] = case value
            when ::Ribbon::Object then to_hash value
            else value
          end
        end
      end
    end

    # If <tt>object</tt> is a Hash, converts it to a Ribbon::Object. If it is
    # an Array, converts any hashes inside.
    def convert(object)
      case object
        when ::Hash then ::Ribbon::Object.new object
        when ::Array then object.map { |element| convert element }
        else object
      end
    end

    # Converts all values in the given ribbon.
    def convert_all!(ribbon)
      each(ribbon) do |key, value|
        ribbon[key] = case value
          when ::Ribbon::Object then convert_all! value
          else convert value
        end
      end
      ribbon
    end

  end

end
