module Fauna
  class Resource
    def self.class_for_name(class_name)
      klass = Fauna.instance_variable_get("@_classes")[class_name]
      klass = Fauna::Class if klass.nil? && class_name =~ %r{^classes/[^/]+$}
      klass
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
      when %r{^.+/local$}
        "timelines"
      when %r{^.+/follows$}
        "timelines"
      when %r{^.+/followers$}
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

      if klass = class_for_name(res.resource_class)
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

    attr_reader :struct

    alias :to_hash :struct

    def initialize(attrs = {})
      @struct = { 'ref' => nil, 'ts' => nil, 'deleted' => false }
      assign(attrs)
    end

    def ref; struct['ref'] end
    def ts; struct['ts'] end
    def deleted; struct['deleted'] end
    def external_id; struct['external_id'] end
    def data; struct['data'] ||= {} end
    def references; struct['references'] ||= {} end
    def changes; Timeline.new("#{ref}/changes") end
    def follows; Timeline.new("#{ref}/follows") end
    def followers; Timeline.new("#{ref}/followers") end
    def local; Timeline.new("#{ref}/local") end

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
