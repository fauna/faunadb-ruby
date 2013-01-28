
module Fauna
  class TimelineEvent

    attr_reader :ts, :timeline_ref, :resource_ref, :action

    def initialize(attrs)
      # TODO v1
      # @ts = attrs['ts']
      # @timeline_ref = attrs['timeline']
      # @resource_ref = attrs['resource']
      # @action = attrs['action']
      @ts, @action, @resource_ref = *attrs
    end

    def resource
      Fauna::Resource.find(resource_ref)
    end

    def timeline
      Timeline.new(timeline_ref)
    end
  end

  class TimelinePage < Fauna::Resource

    resource_class "timelines"

    def events
      @events ||= struct['events'].map { |e| TimelineEvent.new(e) }
    end
  end

  class Timeline
    attr_reader :ref

    def initialize(ref)
      @ref = ref
    end

    def page(query = nil)
      TimelinePage.find(ref, query)
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

  class TimelineSettings < Fauna::Resource

    resource_class "timelines/settings"

    def initialize(name, attrs = {})
      super(attrs)
      struct['ref'] = "timelines/#{name}"
    end
  end
end
