module Fauna
  module Model
    class InvalidSchema < RuntimeError; end
    class InvalidOperation < RuntimeError; end
    class InvalidInstance < RuntimeError; end

    class DuplicateValue < RuntimeError
      attr_reader :model
      attr_reader :fields

      def initialize(model, fields)
        @model = model
        @fields = fields

        super("Duplicate values at fields: #{fields.join(', ')}")
      end

      def self.raise_for_exception(e, model)
        paths = []
        e.errors.each do |error|
          if error.code == 'validation failed'
            error.failures.each do |failure|
              if failure.code == 'duplicate value'
                paths << failure.field
              end
            end
          end
        end

        unless paths.empty?
          fields = []
          paths.each do |path|
            model.fields.each do |name, params|
              if params[:path] == path
                fields << name
              end
            end
          end
          raise DuplicateValue.new(model, fields)
        end
      end
    end
  end
end
