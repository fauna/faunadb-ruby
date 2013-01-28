
module Fauna
  class Publisher < Fauna::Model
    extend Fauna::Model::Fields
    extend Fauna::Model::Timelines

    def self.find
      super("publisher")
    end
  end
end
