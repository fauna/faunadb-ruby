module Fauna
  class ClassSettings < Fauna::Resource; end

  class Class < Fauna::Model
    class << self
      def ref
        @ref ||= "classes/#{name.split("::").last.underscore}"
      end

      def class_name
        ref.split("/", 2).last
      end

      def resource
        @class_resource ||= ClassSettings.alloc("ref" => ref, "data" => {})
      end

      delegate :data=, :data, :ts, :save!, :to => :resource

      def load!
        @class_resource = ClassSettings.alloc(Fauna::Resource.find(ref).to_hash)
      end

      def destroy!
        class_resource.destroy
      end

      def find_by_external_id(external_id)
        find_by("instances", :external_id => external_id, :class => class_name)
      end
    end

    def class_name
      self.class.class_name
    end

    private

    def post
      Fauna::Client.post("instances", struct.merge("class" => class_name))
    end
  end
end
