module Fauna
  class NamedResource < Fauna::Resource
    def name; struct['name'] end

    def ref; @ref ||= "#{fauna_class}/#{name}" end

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

    def find_by_constraint(*args); Fauna::Resource.find_by_constraint(ref, *args); end

    def new(*args); Fauna::Resource.new(ref, *args) end

    def create(ref, *args); Fauna::Resource.create(ref, *args) end
  end

  class User < Fauna::Resource
    def self.all; Fauna::Set.new('users/instances') end

    def self.self; find("users/self") end

    def initialize(attrs = {}); super('users', attrs) end
  end

  class Settings < Fauna::Resource
    def self.all; Fauna::Set.new('settings/instances') end

    def self.self; find("settings/self") end

    def self.find_by_email(email)
      escaped_email = CGI.escape(email)
      find("settings/email/#{escaped_email}")
    end

    def email; struct['email']; end
  end

end
