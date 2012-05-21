class Ribbon < BasicObject

  # Extensions to the standard library.
  #
  # @author Matheus Afonso Martins Moreira
  # @since 0.6.0
  module CoreExtensions; end

end

%w(array basic_object hash object).each do |file|
  require file.prepend 'ribbon/core_extensions/'
end
