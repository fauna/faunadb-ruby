
module Fauna
  class Publisher < Fauna::Resource
    def self.find
      find_by_ref("publisher")
    end
  end
end
