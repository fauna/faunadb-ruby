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
        resources[ref] = object_or_ref
      else
        Fauna::Event.create(@timeline_ref, object_or_ref)
      end
    end

    def remove(object_or_ref)
      if object_or_ref.respond_to?(:ref)
        ref = object_or_ref.ref
        Fauna::Event.delete(@timeline_ref, ref)
        resources[ref] = nil
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
      resources.each do |key, value|
        yield value
      end
    end

    def [](key)
      resources[key]
    end

    def reload
      res = {}
      references = events["references"]
      references.each do |ref, reference|
        if class_name = reference["class"]
          scope = class_name.split('::')[0..-2].join('::')
          reference_class = "#{scope}::#{class_name}".constantize
          res[ref] = reference_class.new(reference.slice("ref", "ts", "data"))
        end
      end
      return res
    end
  end
end
