module Fauna
  class ClassSettings < Fauna::Resource; end

  class Class < Fauna::Model
    class << self
      def ref
        fauna_class_name
      end

      def class_name
        fauna_class_name.split("/", 2).last
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

      def find_by_external_id(external_id)
        find_by("instances", :external_id => external_id, :class => class_name)
      end
    end

    # FIXME https://github.com/fauna/issues/issues/16
    def external_id
      struct['external_id']
    end

    private

    def post
      Fauna::Client.post("instances", struct.merge("class" => self.class.class_name))
    end
  end
end
