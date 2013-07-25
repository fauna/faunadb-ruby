
module Fauna
  class Settings < Fauna::Model

    def self.self
      find_by_ref("settings/self")
    end

    def self.find_by_email(email)
      find_by_ref("settings/email/#{email}")
    end

    # set on user create
    def email; struct['email']; end
    def password; struct['password']; end
  end
end
