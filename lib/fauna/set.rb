
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
      Set.new(set_ref)
    end
  end

  class EventsPage < Fauna::Resource
    include Enumerable

    def self.find(ref, query = nil)
      if query
        query = query.merge(:before => query[:before]) if query[:before]
        query = query.merge(:after => query[:after]) if query[:after]
      end

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

  class SetPage < Fauna::Resource
    include Enumerable

    def self.find(ref, query = nil)
      alloc(Fauna::Client.get(ref, query).to_hash)
    end

    def refs
      @refs ||= struct['resources'].map { |e| SetRef.new("resource" => e) }
    end

    def resources
      refs.map(&:resource)
    end

    def each(&block)
      resources.each(&block)
    end

    def empty?
      resources.empty?
    end
  end

  class Set
    attr_reader :ref

    def initialize(ref)
      @ref = ref
    end

    def page(query = nil)
      SetPage.find(ref, query)
    end

    def resources(query = nil)
      page(query).resources
    end

    def eventsPage(query = nil)
      EventsPage.find("#{ref}/events", query)
    end

    def events(query = nil)
      eventsPage(query).events
    end

    def self.join(*args)
      SetQuery.new('join', *args)
    end

    def self.union(*args)
      SetQuery.new('union', *args)
    end

    def self.intersection(*args)
      SetQuery.new('intersection', *args)
    end

    def self.difference(*args)
      SetQuery.new('difference', *args)
    end

    def self.query(&block)
      module_eval(&block)
    end
  end

  class CustomSet < Set
    def add(resource)
      self.class.add(ref, resource)
    end

    def remove(resource)
      self.class.remove(ref, resource)
    end

    def self.add(ref, resource)
      resource = resource.ref if resource.respond_to?(:ref)
      Fauna::Client.put("#{ref}/#{resource}")
    end

    def self.remove(ref, resource)
      resource = resource.ref if resource.respond_to?(:ref)
      Fauna::Client.delete("#{ref}/#{resource}")
    end
  end

  class SetQuery < Set
    def initialize(function, *params)
      @function = function
      @params = params
    end

    def query
      @query ||= begin
        param_strings = @params.map do |p|
          p.respond_to?(:query) ? p.query : (p.respond_to?(:ref) ? p.ref : p)
        end

        "#{@function}(#{param_strings.join(',')})"
      end
    end

    def ref
      "query?q=#{query}"
    end

    def page(query = nil)
      EventsPage.find("query", (query || {}).merge(:q => self.query))
    end

    def eventsPage(query = nil)
      SetPage.find("query", (query || {}).merge(:q => "events(#{self.query})"))
    end
  end

  class SetConfig < Fauna::Resource
    def initialize(parent_class, name, attrs = {})
      super(attrs)
      struct['ref'] = "#{parent_class}/sets/#{name}"
    end
  end
end
