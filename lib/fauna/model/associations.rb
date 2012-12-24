module Fauna
  class Model
    class TimelineCollection
      attr_reader :resources

      def initialize(name, resource_ref)
        @timeline = Fauna::Timeline.new(resource_ref, "timelines/#{name.to_s}")
        load_timeline
      end

      def add(resource)
        @timeline.add(resource.ref)
        @resources[resource.ref] = resource
      end

      def remove(resource)
        @timeline.remove(resource.ref)
        @resources.delete(resource.ref)
      end

      def each(klass = nil, &block)
        resources = klass ? @resources.select { |k, v| v.class == klass }.values : @resources
        resources.each(&block)
      end

      def inspect
        @resources.inspect
      end

      def values
        @resources.values
      end

      def [](key)
        @resources[key]
      end

      private
      def load_timeline
        @resources = {}
        references = @timeline.events["references"]
        references.each do |ref, reference|
          if class_name = reference["class"]
            reference_class = Module.const_get(class_name)
            @resources[ref] = reference_class.new(reference.slice("ref", "ts", "data"))
          end
        end
      end
    end
  end
end
