module Fauna
  module Model
    module Dirty
      attr_reader :previous_changes

      def changed?
        !changed.empty?
      end

      def changed
        changed_fields.keys
      end

      def changes
        fields = changed_fields
        fields.merge(fields) { |_, v| field_change(v) }
      end

      def changed_attributes
        fields = changed_fields
        fields.merge(fields) { |_, v| field_was(v) }
      end

      def reset_changes
        init_state
      end

    private

      def field_changed?(params)
        old = Model.get_path(params[:path], @original)
        new = Model.get_path(params[:path], @current)

        Model.calculate_diff?(old, new)
      end

      def field_change(params)
        old = Model.get_path(params[:path], @original)
        new = Model.get_path(params[:path], @current)

        unless params[:codec].nil?
          old = params[:codec].decode(old)
          new = params[:codec].decode(new)
        end

        [old, new]
      end

      def field_was(params)
        old = Model.get_path(params[:path], @original)
        old = params[:codec].decode(old) unless params[:codec].nil?
        old
      end

      def reset_field!(params)
        old = Model.get_path(params[:path], @original)
        old = Model.hash_dup(old)
        Model.set_path(params[:path], old, @current)
      end

      def changed_fields
        self.class.fields.select { |_, v| field_changed?(v) }
      end
    end
  end
end
