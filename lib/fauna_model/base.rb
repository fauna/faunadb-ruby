module Fauna
  module Model
    class Base
      class << self
        def fauna_class
          @fauna_class || fail(InvalidClass.new('No class set'))
        end

        def fauna_class=(fauna_class)
          @fauna_class = fauna_class

          field 'ref', 'ref', internal_readonly: true
          field 'ts', 'ts', internal_readonly: true
          field 'class', 'class', internal_readonly: true

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
          fields[name] = params.merge(path: Array(path))

          define_method(name) do
            field_getter(params)
          end

          return if params[:internal_readonly]
          define_method("#{name}=") do |value|
            field_setter(params, value)
          end
        end

        def from_fauna(resource)
          model = allocate
          model.send(:from_resource, resource)
          model
        end

        def create!(params = {})
          model = new(params)
          model.save!
          model
        end

        def find(identifier)
          identifier = Fauna::Ref.new("#{fauna_class}/#{identifier}") unless identifier.is_a? Ref

          from_fauna(Fauna::Context.query(Fauna::Query.get(identifier)))
        end

      private

        def get_path(path, data)
          path.inject(data) do |obj, element|
            break unless obj.is_a? Hash
            obj[element]
          end
        end

        def set_path(path, value, data)
          last_key = path.pop
          data = path.inject(data) do |obj, element|
            obj[element] = {} unless obj[element].is_a? Hash
            obj[element]
          end
          data[last_key] = value
        end

        def delete_path(path, data)
          last_key = path.pop
          data = path.inject(data) do |obj, element|
            break unless obj[element].is_a? Hash
            obj[element]
            continue
          end
          data.delete(last_key) if data.is_a? Hash
        end

        def deep_dup(obj)
          if obj.is_a? Hash
            obj.each_with_object({}) do |(key, value), object|
              object[key] = deep_dup(value)
            end
          else
            obj.dup
          end
        end

        def calculate_diff(source, updated)
          (source.keys | updated.keys).each_with_object({}) do |key, diff|
            if source.key? key
              if updated.key? key
                old = source[key]
                new = updated[key]
                if old.is_a?(Hash) && new.is_a?(Hash)
                  inner_diff = calculate_diff(old, new)
                  diff[key] = inner_diff unless inner_diff.empty?
                elsif old != new
                  diff[key] = new
                end
              else
                diff[key] = nil
              end
            else
              diff[key] = updated[key]
            end
          end
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
        !new_record? && self.class.calculate_diff(@original, @current).empty?
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
        return if new_record?
        Fauna::Context.query(delete_query)
        @deleted = true
      end

    private

      def create_query
        Fauna::Query.create(self.class.fauna_class, Fauna::Query.quote(query_params))
      end

      def replace_query
        Fauna::Query.replace(@current['ref'], Fauna::Query.quote(query_params))
      end

      def update_query
        Fauna::Query.update(@current['ref'], Fauna::Query.quote(self.class.calculate_diff(@original, @current)))
      end

      def delete_query
        Fauna::Query.delete(ref)
      end

      def query_params
        params = self.class.deep_dup(@current)

        # Remove unsettable fields
        self.class.fields.each do |value|
          if value[:internal_readonly] || (value[:internal_writeonce] && !new_record?)
            self.class.delete_path(value[:path], params)
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
        @current = self.class.deep_dup(@original)
        @cache = {}
        @deleted = false
      end

      def from_resource(resource)
        unless resource['class'].nil? || resource['class'] == self.class.fauna_class
          fail InvalidClass.new('Resource class does not match model class')
        end

        @original = resource
        init_state
      end

      def field_getter(params)
        path = params[:path]

        if params[:codec].nil?
          self.class.get_path(path, @current)
        else
          unless @cache.key?(path)
            @cache[path] = params[:codec].decode(self.class.get_path(path, @current))
          end
          @cache[path]
        end
      end

      def field_setter(params, value)
        if params[:internal_writeonce] && !new_record?
          fail InvalidOperation.new('This field can only be set on new instances')
        end

        path = params[:path]

        unless params[:codec].nil?
          @cache[path] = value
          value = params[:codec].encode(value)
        end

        set_path(path, value, @current)
      end

      def copy
        new_model = self.class.allocate
        new_model.instance_variable_set(:original, @original)
        new_model.instance_variable_set(:current, self.class.deep_dup(@current))
        new_model.instance_variable_set(:cache, @cache.dup)
        new_model
      end
    end
  end
end
