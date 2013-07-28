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
    def self.all; Fauna::Set.new("databases") end

    def self.self; find("databases/self") end

    def initialize(attrs = {}); super('databases', attrs) end
  end

  class Class < Fauna::NamedResource
    def self.all; Fauna::Set.new("classes") end

    def initialize(attrs = {}); super('classes', attrs) end

    def all; Fauna::Set.new("#{ref}/instances") end

    def find(*args); Fauna::Resource.find(*args); end

    def find_by_constraint(*args); Fauna::Resource.find_by_constraint(ref, *args); end

    def new(*args); Fauna::Resource.new(ref, *args) end

    def create(*args); Fauna::Resource.create(ref, *args) end
  end

  class User
    def self.all; Fauna::Set.new('users/instances') end

    def self.self; Fauna::Resource.find("users/self") end

    def self.new(*args); Fauna::Resource.new('users', *args) end

    def self.create(*args); Fauna::Resource.create('users', *args) end
  end

  class Key
    def self.all(db); Fauna::Set.new("databases/#{db}/keys") end

    def self.new(db, *args); Fauna::Resource.new("databases/#{db}/keys", *args) end

    def self.create(db, *args); Fauna::Resource.create("databases/#{db}/keys", *args) end
  end

  class Token
    def self.new(*args); Fauna::Resource.new('tokens', *args) end

    def self.create(*args); Fauna::Resource.create('tokens', *args) end
  end

  class Settings
    def self.all; Fauna::Set.new('settings/instances') end

    def self.self; Fauna::Resource.find("settings/self") end

    def self.find_by_email(email)
      escaped_email = CGI.escape(email)
      Fauna::Resource.find("settings/email/#{escaped_email}")
    end

    def email; struct['email']; end
  end

end
