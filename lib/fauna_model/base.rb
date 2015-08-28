module Fauna
  module Model
    class Base
      include ActiveModel::Validations
      include Fauna::Model::Dirty

      class << self
        def fauna_class
          @fauna_class || fail(InvalidClass.new('No class set'))
        end

        def fauna_class=(fauna_class)
          @fauna_class = Fauna::Ref.new(fauna_class.to_s)

          field 'ref', path: 'ref', internal_readonly: true
          field 'ts', path: 'ts', internal_readonly: true
          field 'fauna_class', path: 'class', internal_readonly: true

          case @fauna_class
          when 'databases'
            field 'name', path: 'name'
            field 'api_version', path: 'api_version'
          when 'keys'
            field 'database', path: 'database', internal_writeonce: true
            field 'role', path: 'role', internal_writeonce: true
            field 'secret', path: 'secret', internal_readonly: true
            field 'hashed_secret', path: 'hashed_secret', internal_readonly: true
          when 'classes'
            field 'name', path: 'name'
            field 'history_days', path: 'history_days'
            field 'ttl_days', path: 'ttl_days'
            field 'permissions', path: 'permissions'
          when 'indexes'
            field 'name', path: 'name'
            field 'source', path: 'source'
            field 'terms', path: 'terms'
            field 'values', path: 'values'
            field 'unique', path: 'unique'
            field 'permissions', path: 'permissions'
          end
        end

        def fields
          @fields ||= {}
        end

        def field(name, params = {})
          name = name.to_s
          params[:path] = params[:path].nil? ? ['data', name] : Array(params[:path])
          fields[name] = params.merge!(name: name)

          define_method(name) do
            field_getter params
          end

          return if params[:internal_readonly]

          define_method("#{name}_changed?") do
            field_changed? params
          end

          define_method("#{name}_change") do
            field_change params
          end

          define_method("#{name}_was") do
            field_was params
          end

          define_method("reset_#{name}!") do
            reset_field! params
          end

          define_method("#{name}=") do |value|
            field_setter params, value
          end
        end

        def from_fauna(resource)
          model = allocate
          model.send(:init_from_resource!, resource)
          model
        end

        def create(params = {})
          model = new(params)
          model.save
          model
        end

        def create!(params = {})
          model = new(params)
          model.save!
          model
        end

        def find(identifier)
          identifier = Fauna::Ref.new(identifier) if identifier.is_a? String

          from_fauna(Fauna::Context.query(Fauna::Query.get(identifier)))
        end

        def find_by_id(id)
          id = Fauna::Ref.new("#{fauna_class}/#{id}")

          from_fauna(Fauna::Context.query(Fauna::Query.get(id)))
        end
      end # End of self

      def initialize(params = {})
        @original = {}
        init_state
        apply_params params
      end

      def new_record?
        ref.nil?
      end

      def deleted?
        @deleted
      end

      def persisted?
        !new_record? && !Model.calculate_diff?(@original, @current)
      end

      def id
        ref.value.split('/').last unless ref.nil?
      end

      def save(validate = true)
        save!(validate)
        true
      rescue InvalidInstance
        false
      end

      def save!(validate = true)
        fail InvalidInstance.new('Invalid instance data') if validate && invalid?

        old_changes = changes

        if new_record?
          init_from_resource!(Fauna::Context.query(create_query))
        else
          init_from_resource!(Fauna::Context.query(update_query))
        end

        @previous_changes = old_changes

        self
      end

      def update(params = {})
        apply_params(params)
        save
      end

      def update!(params = {})
        apply_params(params)
        save!
      end

      def destroy
        return false if new_record?
        Fauna::Context.query(delete_query)
        @deleted = true
      end

    private

      def create_query
        return nil unless new_record?
        Fauna::Query.create(self.class.fauna_class, Fauna::Query.quote(query_params))
      end

      def replace_query
        return nil if new_record?
        Fauna::Query.replace(@current['ref'], Fauna::Query.quote(query_params))
      end

      def update_query
        return nil if new_record?
        Fauna::Query.update(@current['ref'], Fauna::Query.quote(Model.calculate_diff(@original, @current)))
      end

      def delete_query
        return nil if new_record?
        Fauna::Query.delete(ref)
      end

      def query_params
        params = Model.hash_dup(@current)

        # Remove unsettable fields
        self.class.fields.each_value do |value|
          if value[:internal_readonly] || (value[:internal_writeonce] && !new_record?)
            Model.delete_path(value[:path], params)
          end
        end

        params
      end

      def apply_params(params = {})
        params.each do |name, value|
          public_send("#{name}=", value)
        end
      end

      def init_state
        @current = Model.hash_dup(@original)
        @cache = {}
        @deleted = false
        @previous_changes ||= {}
      end

      def init_from_resource!(resource)
        unless resource['class'].nil? || resource['class'] == self.class.fauna_class
          fail InvalidClass.new('Resource class does not match model class')
        end

        @original = resource
        init_state
      end

      def field_getter(params)
        if params[:codec].nil?
          Model.get_path(params[:path], @current)
        else
          name = params[:name]
          unless @cache.key?(name)
            @cache[name] = params[:codec].decode(Model.get_path(params[:path], @current))
          end
          @cache[name]
        end
      end

      def field_setter(params, value)
        if params[:internal_writeonce] && !new_record?
          fail InvalidOperation.new('This field can only be set on new instances')
        end

        unless params[:codec].nil?
          @cache[params[:name]] = value
          value = params[:codec].encode(value)
        end

        Model.set_path(params[:path], value, @current)
      end

      def copy
        new_model = self.class.allocate
        new_model.instance_variable_set(:original, @original)
        new_model.instance_variable_set(:current, Model.hash_dup(@current))
        new_model.instance_variable_set(:cache, @cache.dup)
        new_model
      end
    end
  end
end
