class Ribbon < BasicObject

  # Ribbon's version.
  module Version

    # Major version.
    #
    # Increments denote backward-incompatible changes and additions.
    MAJOR = 0

    # Minor version.
    #
    # Increments denote backward-compatible changes and additions.
    MINOR = 3

    # Patch version.
    #
    # Increments denote changes in implementation.
    PATCH = 0

    # Build version.
    #
    # Used for pre-release versions.
    BUILD = nil

    # Complete version string, which is every individual version number joined
    # by a dot (<tt>'.'</tt>), in descending order of prescedence.
    STRING = [ MAJOR, MINOR, PATCH, BUILD ].compact.join '.'

  end
end
