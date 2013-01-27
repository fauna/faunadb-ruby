module Fauna
  class Model
    module Fields
      def field(*names)
        names.each do |name|
          name = name.to_s
          define_method(name) { resource.data[name] }
          define_method("#{name}=") do |value|
            resource.data ||= {}
            resource.data[name] = value
          end
        end
      end
    end

    module Timelines
      def timeline(*names)
        names.each do |name|
          timeline_name = "timelines/#{name}"
          @timelines ||= []
          @timelines << timeline_name
          define_method(timeline_name) do
            @timelines[name] ||= Fauna::Timeline.new(ref, timeline_name)
          end
        end
      end
    end

    module References
      def reference(*names)
        names.each do |name|
          name = name.to_s
          ref_name = "#{name}_ref"
          @references ||= []
          @references << name << ref_name
          define_method(ref_name)  { references[name] }
          define_method("#{ref_name}=") { |ref| references[name] = ref }

          define_method(name) do
            if references[name]
              scope = self.class.name.split('::')[0..-2].join('::')
              "#{scope}::#{name.camelize}".constantize.find(references[name])
            end
          end

          define_method("#{name}=") do |object|
            references[name] = object.ref
          end
        end
      end
    end
  end
end
