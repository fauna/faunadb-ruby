
module Fauna
  class Event

    attr_reader :ts, :set_ref, :resource_ref, :action

    def initialize(attrs)
      # TODO v1
      @ts = attrs['ts']
      @set_ref = attrs['set']
      @resource_ref = attrs['resource']
      @action = attrs['action']
    end

    def resource
      Fauna::Resource.find(resource_ref)
    end

    def set
      EventSet.new(set_ref)
    end
  end

  class EventSetPage < Fauna::Resource
    def events
      @events ||= struct['events'].map { |e| Event.new(e) }
    end

    def any?
      struct['events'].any?
    end

    def resources
      # TODO duplicates can exist in the local event_set. remove w/ v1
      seen = {}
      events.inject([]) do |a, ev|
        if (ev.action == 'create' && !seen[ev.resource_ref])
          seen[ev.resource_ref] = true
          a << ev.resource
        end

        a
      end
    end
  end

  class EventSet
    attr_reader :ref

    def initialize(ref)
      @ref = ref
    end

    def page(query = nil)
      EventSetPage.find(ref, query)
    end

    def events(query = nil)
      page(query).events
    end

    def resources(query = nil)
      page(query).resources
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
