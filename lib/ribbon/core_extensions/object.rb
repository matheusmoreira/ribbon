class Ribbon < BasicObject
  module CoreExtensions

    # Methods available to all objects.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.6.0
    module Object
    end

    ::Object.send :include, ::Ribbon::CoreExtensions::Object

  end
end

%w(

ribbon/core_extensions/object/option_scope
ribbon/core_extensions/object/yield_or_eval

).each { |file| require file }
