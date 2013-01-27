module Fauna
  class Class < Fauna::Model
    class << self
      attr_reader :class_resource

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

    delegate :data=, :data, :user, :external_id=, :external_id, :to => :resource

    def self.init
      super
      @class_resource = Fauna::Client::Resource.new(
        "ref" => "classes/#{name.split("::").last.underscore}",
      "data" => {})

      @fields += ["data", "email", "user", "external_id"]
    end

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
