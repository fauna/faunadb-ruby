
module Fauna
  class User < Fauna::Model
    extend Fauna::Model::Fields
    extend Fauna::Model::References
    extend Fauna::Model::Timelines

    resource_class "users"

    timeline :changes, :follows, :followers, :internal => true

    def self.find_by_email(email)
      find_by("users", {"email" => email})
    end

    def self.find_by_external_id(external_id)
      find_by("users", {"external_id" => external_id})
    end

    def self.find_by_name(name)
      find_by("users", {"name" => name})
    end

    private

    def post
      Fauna::Client.post("users", struct)
    end
  end
end
