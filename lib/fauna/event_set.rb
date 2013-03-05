
module Fauna
  class SetRef
    attr_reader :ts, :resource_ref

    def initialize(attrs)
      @ts = attrs['ts']
      @resource_ref = attrs['resource']
    end

    def resource
      Fauna::Resource.find(resource_ref)
    end
  end

  class Event < SetRef
    attr_reader :set_ref, :action

    def initialize(attrs)
      super(attrs)
      @set_ref = attrs['set']
      @action = attrs['action']
    end

    def set
      EventSet.new(set_ref)
    end
  end

  class EventsPage < Fauna::Resource
    include Enumerable

    def self.find(ref, query = nil)
      alloc(Fauna::Client.get(ref, query).to_hash)
    end

    def events
      @events ||= struct['events'].map { |e| Event.new(e) }
    end

    def each(&block)
      events.each(&block)
    end

    def empty?
      events.empty?
    end
  end

  class RefsPage < Fauna::Resource
    include Enumerable

    def self.find(ref, query = nil)
      alloc(Fauna::Client.get(ref, query).to_hash)
    end

    def refs
      @refs ||= struct['events'].map { |e| SetRef.new(e) }
    end

    def resources
      refs.map(&:resource)
    end

    def empty?
      events.empty?
    end
  end

  class EventSet
    attr_reader :ref

    def initialize(ref)
      @ref = ref
    end

    def page(query = nil)
      EventsPage.find(ref, query)
    end

    def creates(query = nil)
      RefsPage.find("#{ref}/creates", query)
    end

    def updates(query = nil)
      RefsPage.find("#{ref}/updates", query)
    end

    def events(query = nil)
      page(query).events
    end

    def resources(query = nil)
      creates(query).resources
    end

    def add(resource)
      self.class.add(ref, resource)
    end

    def remove(resource)
      self.class.remove(ref, resource)
    end

    def self.add(ref, resource)
      resource = resource.ref if resource.respond_to?(:ref)
      Fauna::Client.post(ref, 'resource' => resource)
    end

    def self.remove(ref, resource)
      resource = resource.ref if resource.respond_to?(:ref)
      Fauna::Client.delete(ref, 'resource' => resource)
    end
  end

  class EventSetConfig < Fauna::Resource
    def initialize(parent_class, name, attrs = {})
      super(attrs)
      struct['ref'] = "#{parent_class}/sets/#{name}/config"
    end
  end
end
