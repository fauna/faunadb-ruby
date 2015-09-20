module Fauna
  module Model
    class Base
      include ActiveModel::Validations
      include Fauna::Model::Dirty

      def self.inherited(subclass)
        fail InvalidSchema.new("#{self} cannot be inherited from - fauna class set") unless @fauna_class.nil?
      end

      def self.fauna_class
        @fauna_class || fail(InvalidSchema.new('No class set'))
      end

      def self.fauna_class=(fauna_class)
        fail InvalidSchema.new('Class already set') unless @fauna_class.nil?
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

      def self.fields
        if @fields.nil?
          super_fields = superclass.instance_variable_get(:@fields)
          if super_fields.nil?
            @fields = {}
          else
            @fields = Model.hash_dup(super_fields)
          end
        end
        @fields
      end

      def self.field(name, params = {})
        name = name.to_s
        fail InvalidSchema.new("Field #{name} already defined") if fields.key? name

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

      def self.from_fauna(resource)
        model = allocate
        model.send(:init_from_resource!, resource)
        model
      end

      def self.create(params = {})
        model = new(params)
        model.save
        model
      end

      def self.create!(params = {})
        model = new(params)
        model.save!
        model
      end

      def self.find(identifier)
        identifier = Fauna::Ref.new(identifier) if identifier.is_a? String

        from_fauna(Fauna::Context.query(Fauna::Query.get(identifier)))
      end

      def self.find_by_id(id)
        id = Fauna::Ref.new("#{fauna_class}/#{id}")

        from_fauna(Fauna::Context.query(Fauna::Query.get(id)))
      end

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
        return false if validate && invalid?

        old_changes = changes
        init_from_resource!(Fauna::Context.query(save_query))
        @previous_changes = old_changes

        true
      end

      def save!
        fail InvalidInstance.new('Invalid instance data') if invalid?

        old_changes = changes
        init_from_resource!(Fauna::Context.query(save_query))
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

      def save_query
        if new_record?
          create_query
        else
          update_query
        end
      end

      def create_query
        return nil unless new_record?
        Fauna::Query.create(self.class.fauna_class, Fauna::Query.quote(query_params))
      end

      def update_query
        return nil if new_record?
        Fauna::Query.update(@current['ref'], Fauna::Query.quote(Model.calculate_diff(@original, @current)))
      end

      def replace_query
        return nil if new_record?
        Fauna::Query.replace(@current['ref'], Fauna::Query.quote(query_params))
      end

      def delete_query
        return nil if new_record?
        Fauna::Query.delete(ref)
      end

    private

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
          fail InvalidSchema.new('Resource class does not match model class')
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
    end
  end
end
