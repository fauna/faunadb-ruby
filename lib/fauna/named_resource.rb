module Fauna
  class NamedResource < Fauna::Resource
    def name
      struct['name']
    end

    def ref
      super || "#{fauna_class}/#{name}"
    end

    private

    def post
      raise Invalid, "Cannot POST to named resource."
    end
  end
end
