
module Fauna
  class User < Fauna::Model

    class Config < Fauna::Resource; end

    def self.self
      find("users/self")
    end

    def self.find_by_email(email)
      find("users/email/#{email}")
    end

    def config
      Fauna::User::Config.find("#{ref}/config")
    end

    # set on user create
    def email; struct['email']; end
    def password; struct['password']; end
  end
end
