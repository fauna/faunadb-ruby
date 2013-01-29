module Fauna
  class ClassSettings < Fauna::Resource; end

  class Class < Fauna::Model
    class << self
      def inherited(base)
        fc = name.split("::").last.underscore
        Fauna.add_class(fc, base) unless Fauna.exists_class_for_name?(fc)
      end

      def ref
        fauna_class
      end

      def class_name
        fauna_class.split("/", 2).last
      end

      def data
        Fauna::Resource.find(fauna_class).data
      end

      def update_data!(hash = {})
        meta = Fauna::Resource.find(fauna_class)
        block_given? ? yield(meta.data) : meta.data = hash
        meta.save!
      end

      def update_data(hash = {})
        meta = Fauna::Resource.find(fauna_class)
        block_given? ? yield(meta.data) : meta.data = hash
        meta.save
      end

      def find_by_external_id(external_id)
        find_by("instances", :external_id => external_id, :class => class_name)
      end
    end

    private

    def post
      Fauna::Client.post("instances", struct.merge("class" => self.class.class_name))
    end
  end
end
