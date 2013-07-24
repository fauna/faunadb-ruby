
module Fauna
  class Publisher < Fauna::Resource
    def self.find
      find_by_ref("world")
    end
  end
end
