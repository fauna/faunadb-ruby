
module Fauna
  class User < Fauna::Model

    class Config < Fauna::Model; end

    def self.self
      find("users/self")
    end

    def self.find_by_email(email)
      find("users/email/#{email}")
    end

    def email; struct['email']; end

    def password; struct['password']; end

    def config
      Fauna::User::Config.find("#{ref}/config")
    end

    private

    def post
      Fauna::Client.post("users", struct)
    end
  end
end
