
module Fauna
  class World < Fauna::Resource
    def self.find
      find_by_ref("world")
    end
  end
end
