module Fauna
  class Set

    attr_reader :ref

    def initialize(ref)
      @ref = ref
    end

    def page(pagination = {})
      SetPage.find(ref, {}, pagination)
    end

    def events(pagination = {})
      EventsPage.find("#{ref}/events", {}, pagination)
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
      if @function == 'match'
        # Escape strings for match values
        @params = @params[0..1] + @params[2..-1].map do |p|
          if p.is_a?(String)
            p.inspect
          else
            p
          end
        end
      end

      @param_strings ||= @params.map do |p|
        if p.respond_to? :expr
          p.expr
        elsif p.respond_to? :ref
          p.ref
        else
          p.to_s
        end
      end
    end

    def expr
      @expr ||= "#{@function}(#{param_strings.join(',')})"
    end

    def ref
      "queries?q=#{expr}"
    end

    def page(pagination = {})
      SetPage.find('queries', { 'q' => expr }, pagination)
    end

    def events(pagination = {})
      EventsPage.find('queries', { 'q' => "events(#{expr})" }, pagination)
    end
  end

  class EachSet < QuerySet
    def initialize(*params)
      super('each', *params)
    end

    def events(pagination = {})
      query = param_strings.first
      subqueries = param_strings.drop(1).join ','
      EventsPage.find('queries', { 'q' => "each(events(#{query}),#{subqueries})" }, pagination)
    end
  end

  class CustomSet < Set
    def add(resource, time = nil)
      self.class.add(self, resource, time)
    end

    def remove(resource, time = nil)
      self.class.remove(self, resource, time)
    end

    def self.add(set, resource, time = nil)
      set = set.ref if set.respond_to? :ref
      resource = resource.ref if resource.respond_to? :ref
      event = time ? "/events/#{Fauna.usecs_from_time(time)}/create" : ''
      Fauna::Client.put("#{set}/#{resource}#{event}")
    end

    def self.remove(set, resource, time = nil)
      set = set.ref if set.respond_to? :ref
      resource = resource.ref if resource.respond_to? :ref
      event = time ? "/events/#{Fauna.usecs_from_time(time)}/delete" : ''
      Fauna::Client.put("#{set}/#{resource}#{event}")
    end
  end

  class SetPage < Fauna::Resource
    include Enumerable

    def refs
      @refs ||= struct['resources']
    end

    def each(&block)
      refs.each(&block)
    end

    def empty?
      refs.empty?
    end

    def length; refs.length end
    def size; refs.size end
  end

  class EventsPage < Fauna::Resource
    include Enumerable

    def events
      @events ||= struct['events'].map { |e| Event.new(e) }
    end

    def each(&block)
      events.each(&block)
    end

    def empty?
      events.empty?
    end

    def length; events.length end
    def size; events.size end
  end

  class Event
    def initialize(attrs)
      @attrs = attrs
    end

    def ref
      "#{resource}/events/#{@attrs['ts']}/#{action}"
    end

    def event_ref
      if set == resource
        "#{resource}/events/#{@attrs['ts']}/#{action}"
      else
        "#{set}/#{resource}/events/#{@attrs['ts']}/#{action}"
      end
    end

    def ts
      Fauna.time_from_usecs(@attrs['ts'])
    end

    def resource
      @attrs['resource']
    end

    def set
      @attrs['set']
    end

    def action
      @attrs['action']
    end

    def save
      Fauna::Client.put(event_ref) if editable?
    end

    def delete
      Fauna::Client.delete(event_ref) if editable?
    end

    def editable?
      ['create', 'delete'].include? action
    end
  end
end
