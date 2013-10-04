module Fauna
  class Resource
    def self.resource_subclass(fauna_class)
      case fauna_class
      when 'databases' then Fauna::NamedResource
      when 'classes' then Fauna::NamedResource
      when 'resources' then Fauna::SetPage
      when 'events' then Fauna::EventsPage
      else Fauna::Resource
      end
    end

    def self.hydrate(struct)
      obj = resource_subclass(struct['class']).allocate
      obj.instance_variable_set '@struct', struct
      obj
    end

    def self.new(fauna_class, attrs = {})
      obj = resource_subclass(fauna_class).allocate
      obj.instance_variable_set '@struct', { 'ref' => nil, 'ts' => nil, 'deleted' => false, 'class' => fauna_class }
      obj.send(:assign, attrs)
      obj
    end

    def self.create(*args)
      new(*args).tap(&:save)
    end

    def self.find(ref, query = {}, pagination = {})
      hydrate(Fauna::Client.get(ref, query, pagination))
    end

    attr_reader :struct

    alias :to_hash :struct

    def ts
      struct['ts'] ? Fauna.time_from_usecs(struct['ts']) : nil
    end

    def ts=(time)
      struct['ts'] = Fauna.usecs_from_time(time)
    end

    def ref; struct['ref'] end
    def fauna_class; struct['class'] end
    def deleted; struct['deleted'] end
    def constraints; struct['constraints'] ||= {} end
    def data; struct['data'] ||= {} end
    def references; struct['references'] ||= {} end

    def events(pagination = {})
      EventsPage.find("#{ref}/events", {}, pagination)
    end

    def set(name)
      CustomSet.new("#{ref}/sets/#{CGI.escape(name)}")
    end

    def eql?(other)
      self.fauna_class == other.fauna_class && self.ref == other.ref && self.ref != nil
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

    def persisted?; !(new_record? || deleted?) end

    def save
      @struct = (new_record? ? post : put).to_hash
    end

    def delete
      Fauna::Client.delete(ref) if persisted?
      struct['deleted'] = true
      struct.freeze
      nil
    end

    private

    # TODO: make this configurable, and possible to invert to a white list
    UNASSIGNABLE_ATTRIBUTES = %w(ts deleted fauna_class).inject({}) { |h, attr| h.update attr => true }

    def assign(attributes)
      attributes.each do |name, val|
        send "#{name}=", val unless UNASSIGNABLE_ATTRIBUTES[name.to_s]
      end
    end

    def put
      Fauna::Client.put(ref, struct)
    end

    def post
      Fauna::Client.post("classes/#{fauna_class}", struct)
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
