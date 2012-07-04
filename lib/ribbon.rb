%w(

ribbon/gem
ribbon/options
ribbon/raw

).each { |file| require file }

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
# @since 0.1.0
# @see Ribbon::Raw
class Ribbon

  # The raw ribbon.
  #
  # @return [Ribbon::Raw] this ribbon's raw ribbon
  # @since 0.8.0
  def raw
    @raw ||= Ribbon::Raw.new
  end

  # Sets this ribbon's raw ribbon.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] object the hash-like object
  # @return [Ribbon::Raw] the raw ribbon
  # @since 0.8.0
  def raw=(object)
    @raw = Ribbon.extract_raw_from object
  end

  # Initializes a new ribbon with the given values.
  #
  # If given a block, the ribbon will be yielded to it. If the block doesn't
  # take any arguments, it will be evaluated in the context of the ribbon.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] initial_values the initial values
  # @see #raw=
  # @see Ribbon::Raw#initialize
  def initialize(initial_values = Ribbon::Raw.new, &block)
    self.raw = initial_values
    __yield_or_eval__ &block
  end

  # The hash used by the raw ribbon.
  #
  # @return [Hash] the internal hash of the raw ribbon
  # @since 0.8.0
  def internal_hash
    raw.__hash__
  end

  # Forwards the method, arguments and block to the raw ribbon's hash, if it
  # responds to the method, or to the raw ribbon itself otherwise.
  def method_missing(method, *arguments, &block)
    if (hash = internal_hash).respond_to? method then hash
    else raw end.__send__ method, *arguments, &block
  end

  # Merges everything inside this ribbon with everything inside the given
  # ribbon, creating a new instance in the process.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] ribbon the ribbon with new values
  # @return [Ribbon] a new ribbon containing the results of the deep merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from this ribbon
  # @yieldparam new_value the value from the given ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.8.0
  # @see #deep_merge!
  # @see deep_merge
  def deep_merge(ribbon, &block)
    Ribbon.new Ribbon.deep_merge(self, ribbon, &block)
  end

  # Merges everything inside this ribbon with the given ribbon in place.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] ribbon the ribbon with new values
  # @return [self] this ribbon
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from this ribbon
  # @yieldparam new_value the value from the given ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.8.0
  # @see #deep_merge
  # @see deep_merge!
  def deep_merge!(ribbon, &block)
    Ribbon.deep_merge! self, ribbon, &block
  end

  # Converts this ribbon and all ribbons inside into hashes.
  #
  # @return [Hash] the converted contents of this wrapped ribbon
  # @since 0.8.0
  def to_hash
    to_hash_recursive
  end

  # Converts this ribbon to a hash and serializes it with YAML.
  #
  # @return [String] the YAML string that represents this ribbon
  # @since 0.8.0
  # @see from_yaml
  def to_yaml
    to_hash.to_yaml
  end

  # Delegates to the raw ribbon.
  #
  # @return [String] the string representation of this ribbon
  # @see Ribbon::Raw#to_s
  def to_s(*arguments, &block)
    raw.to_s *arguments, &block
  end

  alias inspect to_s

  private

  # Converts this ribbon and all ribbons inside into hashes using recursion.
  #
  # @return [Hash] the converted contents of this ribbon
  def to_hash_recursive(raw_ribbon = self.raw)
    {}.tap do |hash|
      raw_ribbon.__hash__.each do |key, value|
        hash[key] = case value
          when Ribbon then to_hash_recursive value.raw
          when Ribbon::Raw then to_hash_recursive value
          else value
        end
      end
    end
  end

end

class << Ribbon

  alias [] new

  # Whether the given object is a {Ribbon::Raw raw ribbon}.
  #
  # @param object the object to be tested
  # @return [true, false] whether the object is a raw ribbon
  # @since 0.8.0
  def raw?(object)
    Ribbon::Raw === object
  end

  # Whether the object is compatible with methods that take hashes or ribbons as
  # arguments.
  #
  # @param object the object to be tested
  # @return [true, false] whether the object is a raw ribbon
  # @since 0.8.0
  def compatible?(object)
    [Ribbon, Ribbon::Raw, Hash].any? { |type| type === object }
  end

  # Extracts the hash of a ribbon. Will attempt to convert other objects.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] object the object to convert
  # @return [Hash] the resulting hash
  # @since 0.2.1
  def extract_hash_from(object)
    case object
      when Ribbon, Ribbon::Raw then object.__hash__
      else object.to_hash
    end
  end

  # Extracts a raw ribbon from the given object.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] object the hash-like object
  # @return [Ribbon::Raw] the raw ribbon
  # @since 0.8.0
  def extract_raw_from(object)
    case object
      when Ribbon then object.raw
      when Ribbon::Raw then object
      else Ribbon::Raw.new object.to_hash
    end
  end

  # Deserializes the hash from the string using YAML and uses it to construct a
  # new ribbon.
  #
  # @param [String] string a valid YAML string
  # @return [Ribbon] a new Ribbon
  # @since 0.4.7
  def from_yaml(string)
    Ribbon.new YAML.load(string)
  end

  # Merges the hashes of the given ribbons.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Raw, #to_hash] new_ribbon the ribbon with new values
  # @return [Ribbon] a new ribbon containing the results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.8.0
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
  # @param [Ribbon, Ribbon::Raw, #to_hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Raw, #to_hash] new_ribbon the ribbon with new values
  # @return [Ribbon, Ribbon::Raw, Hash] old_ribbon, which will contain the
  #   results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.8.0
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
  # @param [Ribbon, Ribbon::Raw, #to_hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Raw, #to_hash] new_ribbon the ribbon with new values
  # @return [Ribbon] a new ribbon containing the results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.8.0
  # @see merge
  # @see deep_merge!
  # @see extract_hash_from
  def deep_merge(old_ribbon, new_ribbon, &block)
    deep :merge, old_ribbon, new_ribbon, &block
  end

  # Merges everything inside the given ribbons in place.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Raw, #to_hash] new_ribbon the ribbon with new values
  # @return [Ribbon, Ribbon::Raw, Hash] old_ribbon, which will contain the
  #   results of the merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.8.0
  # @see merge!
  # @see deep_merge
  # @see extract_hash_from
  def deep_merge!(old_ribbon, new_ribbon, &block)
    deep :merge!, old_ribbon, new_ribbon, &block
  end

  private

  # Common logic for deep merge methods.
  #
  # @param [:merge, :merge!] merge_method the method that will be used to merge
  #   recursively
  # @param [Ribbon, Ribbon::Raw, #to_hash] old_ribbon the ribbon with old values
  # @param [Ribbon, Ribbon::Raw, #to_hash] new_ribbon the ribbon with new values
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from old_ribbon
  # @yieldparam new_value the value from new_ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.8.0
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
