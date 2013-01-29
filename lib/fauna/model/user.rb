
module Fauna
  class User < Fauna::Model
    extend Fauna::Model::Fields
    extend Fauna::Model::References
    extend Fauna::Model::Timelines

    timeline :changes, :follows, :followers, :local, :internal => true

    validates :name, :presence => true

    def self.find_by_email(email)
      find_by("users", :email => email)
    end

    def self.find_by_external_id(external_id)
      find_by("users", :external_id => external_id)
    end

    def self.find_by_name(name)
      find_by("users", :name => name)
    end

    def email
      struct['email']
    end

    def email=(email)
      struct['email'] = email
    end

    # FIXME https://github.com/fauna/issues/issues/16
    def name
      struct['name']
    end

    def external_id
      struct['external_id']
    end

    private

    def post
      Fauna::Client.post("users", struct)
    end
  end
end
