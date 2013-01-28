
module Fauna
  class Publisher < Fauna::Model
    extend Fauna::Model::Fields
    extend Fauna::Model::Timelines

    resource_reader :name, :world_name, :url

    def self.find
      super("publisher")
    end
  end
end
