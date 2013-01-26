module Fauna
  class Invalid < RuntimeError
  end

  class NotFound < RuntimeError
  end

  class Model
    def self.inherited(base)
      base.send :extend, ClassMethods
      base.send :extend, ActiveModel::Naming
      base.send :include, ActiveModel::Validations
      base.send :include, ActiveModel::Conversion
      base.send :include, ActiveModel::Dirty

      # Callbacks support
      base.send :extend, ActiveModel::Callbacks
      base.send :include, ActiveModel::Validations::Callbacks
      base.send :define_model_callbacks, :save, :create, :update, :destroy

      # Serialization
      base.send :include, ActiveModel::Serialization
    end

    module ClassMethods
      attr_accessor :class_name

      attr_reader :ref

      def create(attributes = {})
        obj = new(attributes)
        obj.save
        obj
      end

      def create!(attributes = {})
        obj = new(attributes)
        obj.save!
        obj
      end

      def find(ref)
        attributes = Fauna::Client.get(ref)
        new(attributes)
      rescue RestClient::ResourceNotFound
        raise NotFound.new("Couldn't find resource with ref #{ref}")
      end

      private

      def data_attr(*names)
        names.each do |attribute|
          attr = attribute.to_s
          define_method(attr) { @data[attr] }
          define_method("#{attr}=") { |value| @data[attr] = value }
        end
      end

      def has_timeline(name, options = {})
        custom = options.fetch(:custom, true)
        timeline = custom ? "timelines/#{name.to_s}" : name.to_s
        define_method(name) do
          @timelines[name] ||= Fauna::Timeline.new(@ref, timeline)
        end
      end

      def reference(*names)
        names.each do |attribute|
          attr = attribute.to_s

          define_method("#{attr}_ref")  { @references[attr] }
          define_method("#{attr}_ref=") { |ref| @references[attr] = ref }

          define_method("#{attr}") do
            if @references[attr]
              scope = self.class.name.split('::')[0..-2].join('::')
              "#{scope}::#{attr.camelize}".constantize.find(@references[attr])
            end
          end

          define_method("#{attr}=") do |object|
            @references[attr] = object.ref
          end
        end
      end

      def setup!
        resource = Fauna::Class.create(self.class_name)['resource']
        @ref = resource['ref']
      end
    end

    attr_accessor :ref, :data, :ts

    def initialize(params = {})
      @timelines = {}
      @data = {}
      @references = {}
      @ref = params.delete('ref')
      data_params = params.delete('data') || {}
      assign(params.merge(data_params))
    end

    alias_method :id, :ref

    def save
      if valid?
        run_callbacks(:save) do
          new_record? ? create_resource : update_resource
        end
        true
      else
        false
      end
    end

    def save!
      save || raise(ResourceInvalid)
    end

    def update(attributes)
      assign(attributes) && save
    end

    def destroy
      run_callbacks(:destroy) do
        Fauna::Instance.delete(@ref) if persisted?
        @id = id
        @ref = nil
        @destroyed = true
      end
    end

    def new_record?
      !@ref
    end

    def destroyed?
      !!(@destroyed ||= false)
    end

    def persisted?
      !(new_record? || destroyed?)
    end

    def valid?
      run_callbacks(:validate) do
        super
      end
    end

    def attributes
      { 'ref' => self.ref, 'data' => self.data, 'ts' => self.ts }
    end

    def eql?(object)
      self.class.equal?(object.class) && self.ref == object.ref && !object.new_record?
    end
    alias :== :eql?

    private

    def update_resource
      run_callbacks(:update) do
        Fauna::Client.put(ref, attributes)
      end
    end

    def create_resource
      run_callbacks(:create) do
        response = Fauna::Client.post(self.class.class_name, attributes)
        attributes = response["resource"]
        @ref = attributes.delete("ref")
        data_attributes = attributes.delete("data") || {}
        assign(attributes.merge(data_attributes))
      end
    end

    def assign(attributes = {})
      attributes.each do |(attribute, value)|
        attribute = attribute.to_s
        if self.respond_to?("#{attribute}=")
          self.send("#{attribute}=", value)
        else
          case attribute
          when 'class' then nil
          when 'deleted' then @destroyed = true if value
          else @data[attribute.to_s] = value
          end
        end
      end
      return true
    end

    def read_attribute(attribute)
      @data[attribute.to_s]
    end

    def write_attribute(attribute, value)
      @data[attribute.to_s] = value
    end
  end
end
