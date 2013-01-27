module Fauna
  class Class < Fauna::Model

    extend Fauna::Model::Fields
    extend Fauna::Model::References
    extend Fauna::Model::Timelines

    class << self
      extend Fauna::Model::Timelines

      def class_resource
        @class_resource ||= Fauna::Client::Resource.new(
          "ref" => "classes/#{name.split("::").last.underscore}",
        "data" => {})
      end

      delegate :ref=, :ref, :data=, :data, :ts, :to => :class_resource

      def save!
        @class_resource = Fauna::Client.put(ref, @class_resource.to_hash)
      end

      def reload!
        @class_resource = Fauna::Client.get(ref)
      end

      def destroy!
        Fauna::Client.delete(ref)
        @class_resource.freeze!
      end
    end

    delegate :data=, :data, :user, :external_id=, :external_id, :references, :to => :resource

    private

    def self.find_by_external_id(external_id)
      find_by("instances", {"external_id" => external_id, "class" => class_name })
    end

    def post
      Fauna::Client.post("instances", resource.to_hash.merge("class" => class_name))
    end

    def put
      Fauna::Client.put(ref, resource.to_hash)
    end

    private

    def class_name
      self.class.ref.split("/").last
    end
  end
end
