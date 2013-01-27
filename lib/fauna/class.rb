module Fauna
  class Invalid < RuntimeError
  end

  class NotFound < RuntimeError
  end

  class Class
    def self.inherited(base)
      base.send :extend, MetaClassMethods
      base.init

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

    module MetaClassMethods
      attr_reader :resource, :fields, :timelines, :references

      delegate :ref=, :ref, :data=, :data, :ts, :to => :resource

      def init
        @resource = Fauna::Client::Resource.new(
          "ref" => "classes/#{name.split("::").last.underscore}",
        "data" => {})
        @fields = ["data"]
        @timelines = []
        @references = []
      end

      def save!
        @resource = Fauna::Client.put(ref, @resource.to_hash)
      end

      def reload!
        @resource = Fauna::Client.get(ref)
      end

      def destroy!
        Fauna::Client.delete(ref)
        @resource.freeze!
      end
    end

    module ClassMethods
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
        raise ArgumentError, "#{ref} is not an instance of class #{name}"  if !(ref.include?(self.ref))
        obj = allocate
        obj.resource = Fauna::Client.get(ref)
        obj
      rescue Fauna::Connection::NotFound
        raise NotFound.new("Couldn't find resource with ref #{ref}")
      end

      private

      def field(*names)
        names.each do |name|
          name = name.to_s
          @fields << name
          define_method(name) { resource.data[name] }
          define_method("#{name}=") { |value| resource.data[name] = value }
        end
      end

      def timeline(*names)
        names.each do |name|
          timeline_name = "timelines/#{name}"
          @timelines << timeline_name
          define_method(timeline_name) do
            @timelines[name] ||= Fauna::Timeline.new(ref, timeline_name)
          end
        end
      end

      def reference(*names)
        names.each do |name|
          name = name.to_s
          ref_name = "#{name}_ref"
          @references << name << ref_name
          define_method(ref_name)  { references[name] }
          define_method("#{ref_name}=") { |ref| references[name] = ref }

          define_method(name) do
            if references[name]
              scope = self.class.name.split('::')[0..-2].join('::')
              "#{scope}::#{name.camelize}".constantize.find(references[name])
            end
          end

          define_method("#{name}=") do |object|
            references[name] = object.ref
          end
        end
      end
    end

    DEFAULT = {:ref => nil,
               :ts => nil,
               :user => nil,
               :deleted => false,
               :references => {},
               :data => {}}

    attr_accessor :resource

    delegate :ref, :data=, :data, :ts, :references, :user, :to => :resource

    def initialize(attributes = {})
      @resource = Fauna::Client::Resource.new(DEFAULT)
      assign(attributes)
      @timelines = {}
    end

    def save
      if valid?
        run_callbacks(:save) do
          if new_record?
            run_callbacks(:create) { @resource = Fauna::Client.post(self.class.ref, resource.to_hash) }
          else
            run_callbacks(:update) { @resource = Fauna::Client.put(ref, resource.to_hash) }
          end
        end
        true
      else
        false
      end
    end

    def save!
      save || raise(ResourceInvalid)
    end

    def update(attributes = {})
      assign(attributes)
      @resource = resource.merge(attributes)
      save
    end

    def destroy
      run_callbacks(:destroy) do
        Fauna::Client.delete(ref) if persisted?
        @destroyed = true
        @resource.freeze!
      end
    end

    def new_record?
      ref.nil?
    end

    def destroyed?
      resource.deleted == true
    end

    def persisted?
      !(new_record? || destroyed?)
    end

    def valid?
      run_callbacks(:validate) do
        super
      end
    end

    def eql?(object)
      self.class.equal?(object.class) && self.ref == object.ref && !object.new_record?
    end
    alias :== :eql?

    private

    def assign(attributes)
      attributes.slice(*self.class.fields).each do |name, _|
        self.send("#{name}=", attributes.delete(value))
      end
      attributes.slice(*self.class.references).each do |name, _|
        self.send("#{name}=", attributes.delete(value))
      end
    end
  end
end
