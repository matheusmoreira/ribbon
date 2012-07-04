class Ribbon

  # Extensions to the standard library.
  #
  # @author Matheus Afonso Martins Moreira
  # @since 0.6.0
  module CoreExtensions; end

end

%w(

ribbon/core_extensions/array
ribbon/core_extensions/basic_object
ribbon/core_extensions/hash
ribbon/core_extensions/object

).each { |file| require file }
