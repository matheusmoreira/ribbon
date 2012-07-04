require 'jewel'

class Ribbon

  # Ribbon gem information and metadata.
  #
  # @author Matheus Afonso Martins Moreira
  # @since 0.7.0
  class Gem < ::Jewel::Gem

    root '../..'

    specification ::Gem::Specification.load root.join('ribbon.gemspec').to_s

  end

end
