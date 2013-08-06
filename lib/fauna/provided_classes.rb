module Fauna
  class NamedResource < Fauna::Resource
    def self.fauna_class
      raise NotImplementedError
    end

    def self.find(name, query = {}, pagination = {})
      super("#{fauna_class}/#{name}", query, pagination)
    end

    def self.set
      CustomSet.new(fauna_class)
    end

    def self.new(*args)
      super(fauna_class, *args)
    end

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

  class Database < Fauna::NamedResource
    def self.fauna_class; 'databases' end
  end

  class Class < Fauna::NamedResource
    def self.fauna_class; 'classes' end
  end

  class Key < Fauna::Resource
    def self.new(*args)
      # FIXME is this right?
      super('keys', *args)
    end

    def self.set(database)
      CustomSet.new("databases/#{database}/keys")
    end

    def database
      struct['database'] || ref.split('/keys').first
    end

    private

    def post
      Fauna::Client.post("databases/#{database}/keys", struct)
    end
  end

  class Token < Fauna::Resource
    def self.new(*args)
      super('tokens', *args)
    end

    class << self
      undef set
    end
  end
end
