
module Fauna
  class World < Fauna::Model
    def new_record?
      false
    end

    def self.self
      find_by_ref("worlds/self")
    end
  end
end
