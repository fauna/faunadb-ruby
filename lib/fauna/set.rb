module Fauna
  class Set

    attr_reader :ref

    def initialize(ref)
      @ref = ref
    end

    def page(pagination = {})
      SetPage.find(ref, {}, pagination)
    end

    def resources(pagination = {})
      page(pagination).resources
    end

    def events(pagination = {})
      EventsPage.find("#{ref}/events", pagination)
    end

    # query DSL

    def self.query(&block)
      module_eval(&block)
    end

    def self.union(*args)
      QuerySet.new('union', *args)
    end

    def self.intersection(*args)
      QuerySet.new('intersection', *args)
    end

    def self.difference(*args)
      QuerySet.new('difference', *args)
    end

    def self.merge(*args)
      QuerySet.new('merge', *args)
    end

    def self.join(*args)
      QuerySet.new('join', *args)
    end

    def self.match(*args)
      QuerySet.new('match', *args)
    end

    # although each is handled via the query DSL, it might make more
    # sense to add it as a modifier on Set instances, similar to events.

    def self.each(*args)
      EachSet.new(*args)
    end
  end

  class QuerySet < Set
    def initialize(function, *params)
      @function = function
      @params = params
    end

    def param_strings
      @param_strings ||= @params.map do |p|
        if p.respond_to? :expr
          p.expr
        elsif p.respond_to? :ref
          p.ref
        else
          p
        end
      end
    end

    def expr
      @expr ||= "#{@function}(#{param_strings.join ','})"
    end

    def ref
      "query?q=#{expr}"
    end

    def page(pagination = {})
      SetPage.find('query', { 'q' => expr }, pagination)
    end

    def events(pagination = {})
      EventsPage.find("query", { 'q' => "events(#{expr})" }, pagination)
    end
  end

  class EachSet < QuerySet
    def initialize(*params)
      super('each', *params)
    end

    def events(pagination = {})
      query = param_strings.first
      subqueries = param_strings.drop(1).join ','
      EventsPage.find("query", { 'q' => "each(events(#{query}),#{subqueries})" }, pagination)
    end
  end

  class CustomSet < Set
    def add(resource)
      self.class.add(set, resource)
    end

    def remove(resource)
      self.class.remove(set, resource)
    end

    def self.add(set, resource)
      resource = resource.ref if resource.respond_to? :ref
      Fauna::Client.put("#{set}/#{resource}")
    end

    def self.remove(set, resource)
      resource = resource.ref if resource.respond_to? :ref
      Fauna::Client.delete("#{set}/#{resource}")
    end
  end


  class SetPage < Fauna::Resource
    include Enumerable

    def self.find(ref, query = {}, pagination = {})
      alloc(Fauna::Client.get(ref, query, pagination))
    end

    def refs
      @refs ||= struct['resources']
    end

    def resources
      refs.map {|r| Fauna::Resource.find(r) }
    end

    def each(&block)
      resources.each(&block)
    end

    def empty?
      resources.empty?
    end
  end

  class EventsPage < Fauna::Resource
    include Enumerable

    def self.find(ref, query = {}, pagination = {})
      alloc(Fauna::Client.get(ref, query, pagination))
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

  class Event
    def initialize(attrs)
      @attrs = attrs
    end

    def ts
      Resource.time_from_usecs(@attrs['ts'])
    end

    def resource
      Fauna::Resource.find_by_ref(resource_ref)
    end

    def set
      Set.new(set_ref)
    end

    def resource_ref
      @attrs['resource']
    end

    def set_ref
      @attrs['set']
    end

    def action
      @attrs['action']
    end
  end
end
