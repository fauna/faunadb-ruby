module Fauna
  class Timeline
    include Enumerable

    def initialize(resource_ref, timeline_ref)
      @timeline_ref = "#{resource_ref}/#{timeline_ref}"
    end

    def add(object_or_ref)
      if object_or_ref.respond_to?(:ref)
        ref = object_or_ref.ref
        Fauna::Event.create(@timeline_ref, ref)
        resources << object_or_ref
        resources.flatten!
      else
        Fauna::Event.create(@timeline_ref, object_or_ref)
      end
    end

    def remove(object_or_ref)
      if object_or_ref.respond_to?(:ref)
        ref = object_or_ref.ref
        Fauna::Event.delete(@timeline_ref, ref)
        resources.reject!{ |resource| resource.ref == ref}
      else
        Fauna::Event.delete(@timeline_ref, object_or_ref)
      end
    end

    def events
      Fauna::Event.find(@timeline_ref)
    end

    def resources
      @resources ||= reload
    end

    def each
      resources.each do |resource|
        yield resorce
      end
    end

    def [](index)
      resources[index]
    end

    def size
      resources.size
    end
    alias :length :size

    def reload
      res = []
      _events = events
      references = _events["references"]
      events_res = _events["resource"]["events"].map{|event| event[2]}
      events_res.each do |event|
        reference = references[event]
        if class_name = reference["class"]
          scope = class_name.split('::')[0..-2].join('::')
          reference_class = "#{scope}::#{class_name}".constantize
          res << reference_class.new(reference.slice("ref", "ts", "data"))
        end
      end
      res
    end
  end
end
