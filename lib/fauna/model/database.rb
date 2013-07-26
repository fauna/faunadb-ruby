
module Fauna
  class Database < Fauna::Model
    def new_record?
      false
    end

    def self.self
      find_by_ref("databases/self")
    end
  end
end
