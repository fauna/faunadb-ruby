
module Fauna
  class User < Fauna::Model

    class Config < Fauna::Resource; end

    def self.self
      find_by_ref("users/self")
    end

    def self.find_by_email(email)
      find_by_ref("users/email/#{email}")
    end

    def config
      Fauna::User::Config.find_by_ref("#{ref}/config")
    end

    # set on user create
    def email; struct['email']; end
    def password; struct['password']; end
  end
end
