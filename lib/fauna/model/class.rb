module Fauna
  class Class < Fauna::Model
    class << self
      def new_record?
        false
      end

      def inherited(base)
        fc = name.split("::").last.underscore
        Fauna.add_class(fc, base) unless Fauna.exists_class_for_name?(fc)
      end
    end
  end
end
