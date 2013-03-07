module Fauna
  class ClassConfig < Fauna::Resource; end

  class Class < Fauna::Model
    class << self
      def inherited(base)
        fc = name.split("::").last.underscore
        Fauna.add_class(fc, base) unless Fauna.exists_class_for_name?(fc)
      end

      def config_ref
        "#{fauna_class}/config"
      end

      def data
        Fauna::Resource.find(config_ref).data
      end

      def update_data!(hash = {})
        meta = Fauna::Resource.find(config_ref)
        block_given? ? yield(meta.data) : meta.data = hash
        meta.save!
      end

      def update_data(hash = {})
        meta = Fauna::Resource.find(config_ref)
        block_given? ? yield(meta.data) : meta.data = hash
        meta.save
      end
    end
  end
end
