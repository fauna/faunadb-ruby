module Fauna
  module Model
    class InvalidSchema < RuntimeError; end
    class InvalidOperation < RuntimeError; end
    class InvalidInstance < RuntimeError; end

    class InstanceNotUnique < RuntimeError
      attr_reader :model

      def initialize(model)
        @model = model

        super('Instance not unique')
      end

      def self.raise_for_exception(e, model)
        if e.errors.any? { |error| error.code == 'instance not unique' }
          raise InstanceNotUnique.new(model)
        end
      end
    end
  end
end
