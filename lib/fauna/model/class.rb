module Fauna
  class Class < Fauna::Model

    extend Fauna::Model::Fields
    extend Fauna::Model::References
    extend Fauna::Model::Timelines

    class Meta < Fauna::MutableResource
      extend Fauna::Model::Fields

      private

      alias :post :put
    end

    class << self
      extend Fauna::Model::Timelines

      def ref
        @ref ||= "classes/#{name.split("::").last.underscore}"
      end

      def class_name
        ref.split("/", 2).last
      end

      def class_resource
        @class_resource ||= Meta.alloc("ref" => ref, "data" => {})
      end

      delegate :data=, :data, :ts, :save!, :to => :class_resource

      def load!
        @class_resource = Meta.find(ref)
      end

      def destroy!
        class_resource.destroy
      end

      def find_by_external_id(external_id)
        find_by("instances", {"external_id" => external_id, "class" => class_name })
      end
    end

    resource_accessor :external_id
    timeline :changes, :follows, :followers, :internal => true

    def class_name
      self.class.class_name
    end

    private

    def post
      Fauna::Client.post("instances", struct.merge("class" => class_name))
    end
  end
end
