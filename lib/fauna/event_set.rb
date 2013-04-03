
module Fauna
  class SetRef
    def initialize(attrs)
      @attrs = attrs
    end

    def ts
      Resource.time_from_usecs(@attrs['ts'])
    end

    def resource_ref
      @attrs['resource']
    end

    def resource
      Fauna::Resource.find_by_ref(resource_ref)
    end
  end

  class Event < SetRef
    def set_ref
      @attrs['set']
    end

    def action
      @attrs['action']
    end

    def set
      EventSet.new(set_ref)
    end
  end

  class EventsPage < Fauna::Resource
    include Enumerable

    def self.find(ref, query = nil)
      if query
        query = query.merge(:before => usecs_from_time(query[:before])) if query[:before]
        query = query.merge(:after => usecs_from_time(query[:after])) if query[:after]
      end

      alloc(Fauna::Client.get(ref, query).to_hash)
    end

    def before
      struct['before'] ? Resource.time_from_usecs(struct['before']) : nil
    end

    def after
      struct['after'] ? Resource.time_from_usecs(struct['after']) : nil
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

    def self.join(*args)
      EventSetQuery.new('join', *args)
    end

    def self.union(*args)
      EventSetQuery.new('union', *args)
    end

    def self.intersection(*args)
      EventSetQuery.new('intersection', *args)
    end

    def self.difference(*args)
      EventSetQuery.new('difference', *args)
    end

    def self.query(&block)
      module_eval(&block)
    end
  end

  class CustomEventSet < EventSet
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

  class EventSetQuery < EventSet
    def initialize(function, *params)
      @function = function
      @params = params
    end

    def query
      @query ||=
      begin
        pstrs = @params.map do |p|
          p.respond_to?(:query) ? p.query : "'#{p.respond_to?(:ref) ? p.ref : p}'"
        end

        "#{@function}(#{pstrs.join(',')})"
      end
    end

    def ref
      "query?query=#{query}"
    end

    def page(query = nil)
      EventsPage.find("query", (query || {}).merge(:query => self.query))
    end

    def creates(query = nil)
      RefsPage.find("query/creates", (query || {}).merge(:query => self.query))
    end

    def updates(query = nil)
      RefsPage.find("query/updates", (query || {}).merge(:query => self.query))
    end

  end

  class EventSetConfig < Fauna::Resource
    def initialize(parent_class, name, attrs = {})
      super(attrs)
      struct['ref'] = "#{parent_class}/sets/#{name}/config"
    end
  end
end
