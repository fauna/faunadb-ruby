module Fauna
  class Resource
    module SpecializedFinder
      def find(ref, query = nil)
        # TODO v1 raise ArgumentError, "#{ref} is not an instance of class #{name}"  if !(ref.include?(self.ref))
        alloc(Fauna::Client.get(ref, query).to_hash)
      rescue Fauna::Connection::NotFound
        raise NotFound.new("Couldn't find resource with ref #{ref}")
      end
    end

    @resource_classes = {}

    def self.inherited(base)
      super
      base.extend SpecializedFinder
    end

    # TODO eliminate/simplify once v1 drops
    def resource_class
      @resource_class ||=
        case ref
        when %r{^users/[^/]+$}
          "users"
        when %r{^instances/[^/]+$}
          "classes/#{struct['class']}"
        when %r{^[^/]+/[^/]+/follows/[^/]+/[^/]+$}
          "follows"
        when %r{^.+/timelines/[^/]+$}
          "timelines"
        when %r{^.+/changes$}
          "timelines"
        when %r{^timelines/[^/]+$}
          "timelines/settings"
        when %r{^classes/[^/]+$}
          "classes"
        when %r{^users/[^/]+/settings$}
          "users/settings"
        when "publisher/settings"
          "publisher/settings"
        when "publisher"
          "publisher"
        else
          "undefined"
        end
    end

    def self.find(ref, query = nil)
      res = Fauna::Client.get(ref, query)

      if klass = @resource_classes[res.resource_class]
        klass.alloc(res.to_hash)
      else
        res
      end
    end

    def self.create(*args)
      new(*args).tap { |obj| obj.save }
    end

    def self.create!(*args)
      new(*args).tap { |obj| obj.save! }
    end

    def self.alloc(struct)
      obj = allocate
      obj.instance_variable_set('@struct', struct)
      obj
    end

    class << self
      private

      def resource_class(class_string)
        klasses = Resource.instance_variable_get("@resource_classes")
        klasses.delete_if { |_, klass| klass == self }
        klasses[class_string.to_s] = self
      end
    end

    attr_reader :struct

    alias :to_hash :struct

    def initialize(attrs = {})
      @struct = { 'ref' => nil, 'ts' => nil, 'deleted' => false }
      assign(attrs)
    end

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

    def eql?(other)
      self.class.equal?(other.class) && self.ref == other.ref && self.ref != nil
    end
    alias :== :eql?

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def new_record?; ref.nil? end

    def deleted?; deleted end

    alias :destroyed? :deleted?

    def persisted?; !(new_record? || deleted?) end

    def save
      @struct = (new_record? ? post : put).to_hash
      true
    rescue Fauna::Connection::BadRequest => e
      e.param_errors.each { |field, message| errors[field] = message }
      false
    end

    def save!
      save or raise Invalid, errors.full_messages
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

    UNASSIGNABLE_ATTRIBUTES = %w(res ts deleted)

    def assign(attributes)
      attributes.stringify_keys!
      UNASSIGNABLE_ATTRIBUTES.each { |attr| attributes.delete attr }
      attributes.each { |name, val| struct[name] = val }
    end

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
      struct.include?(field) ? field : nil
    end

    def setter_method(method)
      (/(.*)=$/ =~ method.to_s) ? $1 : nil
    end
  end
end
