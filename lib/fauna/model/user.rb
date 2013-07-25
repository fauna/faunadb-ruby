
module Fauna
  class User < Fauna::Model
    def self.self
      find_by_ref("users/self")
    end
  end
end
