module Fauna
  class Class < Fauna::Model

    extend Fauna::Model::Fields
    extend Fauna::Model::References
    extend Fauna::Model::Timelines

    class Meta < Fauna::Resource
      def data; struct['data'] end
    end

    class << self
      extend Fauna::Model::Timelines

      def ref
        @ref ||= "classes/#{name.split("::").last.underscore}"
      end

      def class_name
        ref.split("/", 2).last
      end

      delegate :data=, :data, :ts, :save!, :to => :class_resource

      def load!
        @class_resource = Meta.find(ref)
      end

      def destroy!
        class_resource.destroy
      end

      def find_by_external_id(external_id)
        find_by("instances", :external_id => external_id, :class => class_name)
      end

      private

      def class_resource
        @class_resource ||= Meta.alloc("ref" => ref, "data" => {})
      end
    end

    timeline :changes, :follows, :followers, :local, :internal => true

    def class_name
      self.class.class_name
    end

    # FIXME https://github.com/fauna/issues/issues/16
    def external_id
      struct['external_id']
    end

    private

    def post
      Fauna::Client.post("instances", struct.merge("class" => class_name))
    end
  end
end
