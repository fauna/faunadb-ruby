
module Fauna
  class Publisher < Fauna::Model
    def self.find
      super("publisher")
    end
  end
end
