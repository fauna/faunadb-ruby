module Fauna
  module Model
    class Base
      class << self
        def fauna_class
          @fauna_class || fail(InvalidClass.new('No class set'))
        end

        def fauna_class=(fauna_class)
          fauna_class = Fauna::Ref.new(fauna_class.to_s) unless fauna_class.is_a? Fauna::Ref
          @fauna_class = fauna_class

          field 'ref', 'ref', internal_readonly: true
          field 'ts', 'ts', internal_readonly: true
          field 'fauna_class', 'class', internal_readonly: true

          case fauna_class
          when 'databases'
            field 'name', 'name'
            field 'api_version', 'api_version'
          when 'keys'
            field 'database', 'database', internal_writeonce: true
            field 'role', 'role', internal_writeonce: true
            field 'secret', 'secret', internal_readonly: true
            field 'hashed_secret', 'hashed_secret', internal_readonly: true
          when 'classes'
            field 'name', 'name'
            field 'history_days', 'history_days'
            field 'ttl_days', 'ttl_days'
            field 'permissions', 'permissions'
          when 'indexes'
            field 'name', 'name'
            field 'source', 'source'
            field 'terms', 'terms'
            field 'values', 'values'
            field 'unique', 'unique'
            field 'permissions', 'permissions'
          end
        end

        def fields
          @fields ||= {}
        end

        def field(name, path, params = {})
          fields[name.to_s] = params.merge!(path: Array(path), name: name.to_s)

          define_method(name) do
            field_getter params
          end

          return if params[:internal_readonly]
          define_method("#{name}=") do |value|
            field_setter params, value
          end
        end

        def from_fauna(resource)
          model = allocate
          model.send(:from_resource, resource)
        end

        def create(params = {})
          model = new(params)
          result = model.save
          if result
            result
          else
            model
          end
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
          id = Fauna::Ref.new("#{fauna_class}/#{id}") unless id.is_a? Fauna::Ref

          from_fauna(Fauna::Context.query(Fauna::Query.get(id)))
        end
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
        !new_record? && Model.calculate_diff(@original, @current).empty?
      end

      def id
        ref.value.split('/').last unless ref.nil?
      end

      def save
        if new_record?
          self.class.from_fauna(Fauna::Context.query(create_query))
        else
          self.class.from_fauna(Fauna::Context.query(update_query))
        end
      end

      def save!
        if new_record?
          from_resource(Fauna::Context.query(create_query))
        else
          from_resource(Fauna::Context.query(update_query))
        end
      end

      def update(params = {})
        model = copy
        model.send(:apply_params, params)
        model.save
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
      end

      def from_resource(resource)
        unless resource['class'].nil? || resource['class'] == self.class.fauna_class
          fail InvalidClass.new('Resource class does not match model class')
        end

        @original = resource
        init_state
        self
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
