require 'ribbon/core_extensions/basic_object'

class Ribbon
  module CoreExtensions

    module Object

      alias yield_or_eval __yield_or_eval__

    end

    ::Object.send :include, ::Ribbon::CoreExtensions::Object

  end
end
