
module Fauna
  class TimelineEvent

    attr_reader :ts, :timeline_ref, :resource_ref, :action

    def initialize(attrs)
      @ts = attrs['ts']
      @timeline_ref = attrs['timeline']
      @resource_ref = attrs['resource']
      @action = attrs['action']
    end

    def resource
      Fauna::Client.get(resource_ref)
    end

    def timeline
      Timeline.new(timeline_ref)
    end
  end

  class TimelinePage < Fauna::Resource
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
      TimelinePage.alloc(Fauna::Client.get(ref, query).to_hash)
    end
  end
end
