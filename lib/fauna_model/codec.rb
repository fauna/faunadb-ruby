module Fauna
  module Model
    class RefCodec
      def decode(value)
        value
      end

      def encode(value)
        case value
        when Fauna::Model::Base
          value.ref
        when Fauna::Ref
          value
        when nil
          nil
        else
          Fauna::Ref.new(value.to_s)
        end
      end
    end

    class ModelCodec
      # TODO: Implement polymorphic finder

      def initialize(model)
        @model = model
      end

      def decode(value)
        @model.find(value) unless value.nil?
      end

      def encode(value)
        case value
        when Fauna::Model::Base
          value.ref
        when Fauna::Ref
          value
        when nil
          nil
        else
          fail ArgumentError.new('Must be a Model, Ref, or nil')
        end
      end
    end
  end
end
