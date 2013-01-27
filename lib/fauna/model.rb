module Fauna
  class Invalid < RuntimeError
  end

  class NotFound < RuntimeError
  end

  class NotImplemented < Exception
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
      attr_accessor :default, :fields, :references, :timelines

      DEFAULT = Fauna::Client::Resource.new(
        :ref => nil,
        :ts => nil,
      :deleted => false)

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
        # TODO v1 raise ArgumentError, "#{ref} is not an instance of class #{name}"  if !(ref.include?(self.ref))
        obj = allocate
        obj.resource = Fauna::Client.get(ref)
        obj
      rescue Fauna::Connection::NotFound
        raise NotFound.new("Couldn't find resource with ref #{ref}")
      end

      private

      def find_by(ref, query)
        # TODO elimate direct manipulation of the connection
        response = Fauna::Client.this.connection.get(ref, query)
        response['resources'].map do |attributes|
          obj = allocate
          obj.resource = Fauna::Client::Resource.new(attributes)
          obj
        end
      rescue Fauna::Connection::NotFound
        []
      end
    end

    attr_accessor :resource

    delegate :ref, :ts, :to => :resource

    def initialize(attributes = {})
      raise Invalid if attributes.nil?
      @resource = Fauna::Model::ClassMethods::DEFAULT.clone
      assign(attributes)
      @destroyed = false
    end

    def save
      if valid?
        run_callbacks(:save) do
          if new_record?
            run_callbacks(:create) { @resource = post }
          else
            run_callbacks(:update) { @resource = put }
          end
        end
        true
      else
        false
      end
    end

    def save!
      save || raise(Invalid)
    end

    def update(attributes = {})
      assign(attributes)
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
      @destroyed ||= false
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

    def to_model
      self
    end

    private

    def post
      raise NotImplemented
    end

    def put
      raise NotImplemented
    end

    def assign(attributes)
      attributes.stringify_keys!
      attributes.each do |name, _|
        self.send("#{name}=", attributes.delete(name))
      end
      attributes.each do |name, _|
        self.send("#{name}=", attributes.delete(name))
      end
    end
  end
end
