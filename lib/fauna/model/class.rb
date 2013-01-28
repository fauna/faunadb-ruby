module Fauna
  class Class < Fauna::Model

    extend Fauna::Model::Fields
    extend Fauna::Model::References
    extend Fauna::Model::Timelines

    class << self
      extend Fauna::Model::Timelines

      def __class_resource__
        @__class_resource__ ||= Fauna::Client::Resource.new(
          "ref" => "classes/#{name.split("::").last.underscore}",
        "data" => {})
      end

      delegate :ref=, :ref, :data=, :data, :ts, :to => :__class_resource__

      def save!
        @__class_resource__ = Fauna::Client.put(ref, @__class_resource__.to_hash)
      end

      def reload!
        @__class_resource__ = Fauna::Client.get(ref)
      end

      def destroy!
        Fauna::Client.delete(ref)
        @__class_resource__.freeze!
      end
    end

    delegate :data=, :data, :user, :external_id=, :external_id, :references, :to => :__resource__

    private

    def self.find_by_external_id(external_id)
      find_by("instances", {"external_id" => external_id, "class" => class_name })
    end

    def post
      Fauna::Client.post("instances", __resource__.to_hash.merge("class" => class_name))
    end

    def put
      Fauna::Client.put(ref, __resource__.to_hash)
    end

    private

    def class_name
      self.class.ref.split("/").last
    end
  end
end
