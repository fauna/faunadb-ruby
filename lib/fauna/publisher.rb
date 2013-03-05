
module Fauna
  class Publisher < Fauna::Resource
    def self.find
      super("publisher")
    end
  end
end
