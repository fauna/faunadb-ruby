
module Fauna
  class Publisher < Fauna::Model
    extend Fauna::Model::Fields
    extend Fauna::Model::Timelines

    delegate :name, :world_name, :url, :data=, :data, :to => :resource

    def self.find
      super("publisher")
    end

    private

    def post
      Fauna::Client.post("publisher", resource.to_hash)
    end

    def put
      Fauna::Client.put(ref, resource.to_hash)
    end
  end
end
