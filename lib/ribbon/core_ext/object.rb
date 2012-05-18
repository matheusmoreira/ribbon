class Ribbon < BasicObject
  module CoreExt

    # Methods available to all objects.
    module Object
    end

    ::Object.send :include, ::Ribbon::CoreExt::Object

  end
end

%w(option_scope yield_or_eval).each do |file|
  require file.prepend 'ribbon/core_ext/object/'
end
