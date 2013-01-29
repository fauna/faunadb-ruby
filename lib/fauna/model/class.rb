module Fauna
  class ClassSettings < Fauna::Resource; end

  class Class < Fauna::Model
    class << self
      def inherited(base)
        fc = name.split("::").last.underscore
        Fauna.add_class(fc, base) unless Fauna.exists_class_for_name?(fc)
      end

      def ref
        fauna_class_name
      end

      def data
        Fauna::Resource.find(fauna_class_name).data
      end

      def update_data!(hash = {})
        meta = Fauna::Resource.find(fauna_class_name)
        block_given? ? yield(meta.data) : meta.data = hash
        meta.save!
      end

      def update_data(hash = {})
        meta = Fauna::Resource.find(fauna_class_name)
        block_given? ? yield(meta.data) : meta.data = hash
        meta.save
      end

      def __class_name__
        @__class_name__ ||= fauna_class_name[8..-1]
      end

      def find_by_external_id(external_id)
        find_by("instances", :external_id => external_id, :class => __class_name__).first
      end
    end

    private

    def post
      Fauna::Client.post("instances", struct.merge("class" => self.class.__class_name__))
    end
  end
end
