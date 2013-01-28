
module Fauna
  class Publisher < Fauna::Model
    extend Fauna::Model::Fields
    extend Fauna::Model::Timelines

    delegate :name, :world_name, :url, :data=, :data, :to => :__resource__

    def self.find
      super("publisher")
    end

    private

    def put
      Fauna::Client.put(ref, __resource__.to_hash)
    end
  end
end
