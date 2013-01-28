module Fauna
  class Invalid < RuntimeError
  end

  class NotFound < RuntimeError
  end

  module Assignable
    def self.extended(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def initialize(attributes = {})
        assign(attributes)
      end

      private

      def assign(attributes)
        attributes.stringify_keys!
        attributes.slice(*self.class.assignable_fields).each do |name, val|
          self.send("#{name}=", val)
        end
      end
    end

    def assignable_fields
      @assignable_fields ||=
        superclass.respond_to?(:assignable_fields) ? superclass.assignable_fields.dup : []
    end

    private

    def assignable_field(*names)
      names.each { |name| assignable_fields << name.to_s }
    end
  end

  module ResourceAccessors
    private

    def resource_reader(*names)
      names.each do |name|
        name = name.to_s
        define_method(name) { @struct[name] }
      end
    end

    def resource_writer(*names)
      names.each do |name|
        name = name.to_s
        assignable_field name
        define_method("#{name}=") { |value| @struct[name] = value }
      end
    end

    def resource_accessor(*names)
      resource_reader(*names)
      resource_writer(*names)
    end
  end

  class Resource
    extend Assignable
    extend ResourceAccessors

    def self.create(attributes = {})
      new(attributes).tap { |obj| obj.save }
    end

    def self.create!(attributes = {})
      new(attributes).tap { |obj| obj.save! }
    end

    def self.alloc(struct)
      obj = allocate
      obj.instance_variable_set('@struct', struct)
      obj
    end

    def self.find(ref)
      # TODO v1 raise ArgumentError, "#{ref} is not an instance of class #{name}"  if !(ref.include?(self.ref))
      alloc(Fauna::Client.get(ref).to_hash)
    rescue Fauna::Connection::NotFound
      raise NotFound.new("Couldn't find resource with ref #{ref}")
    end

    attr_reader :struct

    alias :to_hash :struct

    def initialize(attrs = {})
      @struct = { 'ref' => nil, 'ts' => nil, 'deleted' => false }
      super
    end

    def eql?(other)
      self.class.equal?(other.class) && self.ref == other.ref && self.ref != nil
    end
    alias :== :eql?

    def respond_to?(method, *args)
      !!getter_method(method) || !!setter_method(method) || super
    end

    def method_missing(method, *args)
      if field = getter_method(method)
        struct[field]
      elsif field = setter_method(method)
        struct[field] = args.first
      else
        super
      end
    end

    def new_record?; ref.nil? end

    def deleted?; deleted end

    alias :destroyed? :deleted?

    def persisted?; !(new_record? || deleted?) end

    def save
      @struct = (new_record? ? post : put).struct
      true
    end

    def save!
      save || raise(Invalid)
    end

    def update(attributes = {})
      assign(attributes)
      save
    end

    def delete
      Fauna::Client.delete(ref) if persisted?
      struct['deleted'] = true
      struct.freeze
      nil
    rescue Fauna::Connection::NotAllowed
      raise Invalid, "This resource can not be destroyed."
    end

    alias :destroy :delete

    private

    def put
      Fauna::Client.put(ref, struct)
    rescue Fauna::Connection::NotAllowed
      raise Invalid, "This resource type can not be updated."
    end

    def post
      raise Invalid, "This resource type can not be created."
    end

    def getter_method(method)
      field = method.to_s
      @struct.include?(field) ? field : nil
    end

    def setter_method(method)
      field = method.to_s.sub(/=$/, '')
      @struct.include?(field) ? field : nil
    end
  end
end
