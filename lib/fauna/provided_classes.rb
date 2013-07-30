module Fauna
  class NamedResource < Fauna::Resource
    def name; struct['name'] end

    def ref; super || "#{fauna_class}/#{name}" end

    private

    def post
      raise Invalid, "Cannot POST to named resource."
    end
  end

  class Database < Fauna::NamedResource
    def self.new(*args); super('databases', *args) end
  end

  class Class < Fauna::NamedResource
    def self.new(*args); super('classes', *args) end
  end

  class Key < Fauna::Resource
    def self.new(*args); super('keys', *args) end

    def database
      struct['database'] || ref.split('/keys').first
    end

    private

    def post
      Fauna::Client.post("#{database}/keys")
    end
  end

  class Token < Fauna::Resource
    def self.new(*args); super('tokens', *args) end
  end
end
