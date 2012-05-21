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

%w(option_scope yield_or_eval).each do |file|
  require file.prepend 'ribbon/core_extensions/object/'
end
