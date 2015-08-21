module Fauna
  module Model
    module Dirty
      attr_reader :previous_changes

      def changed?
        !changed.empty?
      end

      def changed
        changed_fields = []
        self.class.fields.each_value do |value|
          changed_fields << value[:name] if field_changed?(value)
        end
        changed_fields
      end

      def changes
        changes_hash = {}
        self.class.fields.each_value do |value|
          changes_hash[value[:name]] = field_change(value) if field_changed?(value)
        end
        changes_hash
      end

      def changed_attributes
        changes_hash = {}
        self.class.fields.each_value do |value|
          changes_hash[value[:name]] = field_was(value) if field_changed?(value)
        end
        changes_hash
      end

      def reset_changes
        init_state
      end

    protected

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
    end
  end
end
