module Fauna
  class Resource # rubocop:disable Metrics/ClassLength
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
      obj.instance_variable_set('@struct', struct)
      obj
    end

    def self.new(fauna_class, attrs = {})
      obj = resource_subclass(fauna_class).allocate
      obj.instance_variable_set('@struct', 'ref' => nil, 'ts' => nil, 'deleted' => false, 'class' => fauna_class)
      obj.struct = attrs
      obj
    end

    def self.create(*args)
      new(*args).tap(&:save)
    end

    def self.find(ref, query = {}, pagination = {})
      hydrate(Fauna::Client.get(ref, query, pagination))
    end

    attr_reader :struct
    alias_method :to_hash, :struct

    def ts
      struct['ts'] ? Fauna.time_from_usecs(struct['ts']) : nil
    end

    def ts=(time)
      struct['ts'] = Fauna.usecs_from_time(time)
    end

    def ref
      struct['ref']
    end

    def fauna_class
      struct['class']
    end

    def deleted
      struct['deleted']
    end

    def constraints
      struct['constraints'] ||= {}
    end

    def data
      struct['data'] ||= {}
    end

    def references
      struct['references'] ||= {}
    end

    def permissions
      struct['permissions'] ||= {}
    end

    def events(pagination = {})
      EventsPage.find("#{ref}/events", {}, pagination)
    end

    def new_event(action, time)
      return unless persisted?

      Fauna::Event.new(
        'resource' => ref,
        'set' => ref,
        'action' => action,
        'ts' => Fauna.usecs_from_time(time),
      )
    end

    def set(name)
      CustomSet.new("#{ref}/sets/#{CGI.escape(name)}")
    end

    def eql?(other)
      fauna_class == other.fauna_class && ref == other.ref && !ref.nil?
    end
    alias_method :==, :eql?

    # dynamic field access

    def respond_to?(method, *args)
      !!getter_method(method) || !!setter_method(method) || super
    end

    def method_missing(method, *args)
      if (field = getter_method(method))
        struct[field]
      elsif (field = setter_method(method))
        struct[field] = args.first
      else
        super
      end
    end

    # object lifecycle

    def new_record?
      ref.nil?
    end

    def deleted?
      !!deleted
    end

    def persisted?
      !(new_record? || deleted?)
    end

    def save
      new_record? ? post : put
    end

    def delete
      Fauna::Client.delete(ref) if persisted?
      struct['deleted'] = true
      struct.freeze
      nil
    end

    def put
      @struct = Fauna::Client.put(ref, struct).to_hash
    end

    def patch
      @struct = Fauna::Client.patch(ref, struct).to_hash
    end

    def post
      @struct = Fauna::Client.post(fauna_class, struct).to_hash
    end

    # TODO: make this configurable, and possible to invert to a white list
    UNASSIGNABLE_ATTRIBUTES = %w(ts deleted fauna_class).inject({}) { |h, attr| h.update attr => true }

    DEFAULT_ATTRIBUTES = { 'data' => {}, 'references' => {}, 'constraints' => {} }

    def struct=(attributes)
      DEFAULT_ATTRIBUTES.merge(attributes).each do |name, val|
        send "#{name}=", val unless UNASSIGNABLE_ATTRIBUTES[name.to_s]
      end
    end

  private

    def getter_method(method)
      field = method.to_s
      struct.include?(field) ? field : nil
    end

    def setter_method(method)
      (/(.*)=$/ =~ method.to_s) ? Regexp.last_match[1] : nil
    end
  end
end
