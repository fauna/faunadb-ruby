module Fauna
  class Resource

    def self.fields; @fields ||= [] end
    def self.event_sets; @event_sets ||= [] end
    def self.references; @references ||= [] end

    # config DSL

    class << self
      attr_accessor :fauna_class

      def fauna_class
        @fauna_class or raise MissingMigration, "Class #{name} has not been added to Fauna.schema."
      end

      private

      def field(*names)
        names.each do |name|
          name = name.to_s
          fields << name
          fields.uniq!

          define_method(name) { data[name] }
          define_method("#{name}=") { |value| data[name] = value }
        end
      end

      def event_set(*names)
        args = names.last.is_a?(Hash) ? names.pop : {}

        names.each do |name|
          set_name = args[:internal] ? name.to_s : "sets/#{name}"
          event_sets << set_name
          event_sets.uniq!

          define_method(name.to_s) { Fauna::CustomEventSet.new("#{ref}/#{set_name}") }
        end
      end

      def reference(*names)
        names.each do |name|
          name = name.to_s
          references << name
          references.uniq!

          define_method("#{name}_ref") { references[name] }
          define_method("#{name}_ref=") { |ref| (ref.nil? || ref.empty?) ? references.delete(name) : references[name] = ref }

          define_method(name) { Fauna::Resource.find(references[name]) if references[name] }
          define_method("#{name}=") { |obj| obj.nil? ? references.delete(name) : references[name] = obj.ref }
        end
      end

      # secondary index helper

      def find_by(ref, query)
        # TODO elimate direct manipulation of the connection
        response = Fauna::Client.this.connection.get(ref, query)
        response['resources'].map { |attributes| alloc(attributes) }
      rescue Fauna::Connection::NotFound
        []
      end
    end

    def self.find(ref, query = nil)
      res = Fauna::Client.get(ref, query)
      Fauna.class_for_name(res.fauna_class).alloc(res.to_hash)
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

    attr_reader :struct

    alias :to_hash :struct

    def initialize(attrs = {})
      @struct = { 'ref' => nil, 'ts' => nil, 'deleted' => false }
      assign(attrs)
    end

    def ref; struct['ref'] end
    def fauna_class; struct['class'] end
    def ts; struct['ts'] end
    def deleted; struct['deleted'] end
    def unique_id; struct['unique_id'] end
    def data; struct['data'] ||= {} end
    def references; struct['references'] ||= {} end
    def changes; EventSet.new("#{ref}/changes") end

    def eql?(other)
      self.class.equal?(other.class) && self.ref == other.ref && self.ref != nil
    end
    alias :== :eql?


    # dynamic field access

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

    # object lifecycle

    def new_record?; ref.nil? end

    def deleted?; deleted end

    alias :destroyed? :deleted?

    def persisted?; !(new_record? || deleted?) end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def save
      @struct = (new_record? ? post : put).to_hash
      true
    rescue Fauna::Connection::BadRequest => e
      e.param_errors.each { |field, message| errors[field] = message }
      false
    end

    def save!
      save || (raise Invalid, errors.full_messages)
    end

    def update(attributes = {})
      assign(attributes)
      save
    end

    def update!(attributes = {})
      assign(attributes)
      save!
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

    # TODO: make this configurable, and possible to invert to a white list
    UNASSIGNABLE_ATTRIBUTES = %w(ref ts deleted).inject({}) { |h, attr| h.update attr => true }

    def assign(attributes)
      attributes.each do |name, val|
        send "#{name}=", val unless UNASSIGNABLE_ATTRIBUTES[name.to_s]
      end
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
