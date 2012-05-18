require 'ribbon/core_ext/basic_object'

class Ribbon < BasicObject
  module CoreExt

    module Object

      alias yield_or_eval __yield_or_eval__

    end

    ::Object.send :include, ::Ribbon::CoreExt::Object

  end
end
