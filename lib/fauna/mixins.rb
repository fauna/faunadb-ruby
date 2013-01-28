module Fauna
  class Model
    module Fields
      def self.extended(base)
        base.send :include, InstanceMethods
      end

      module InstanceMethods
        def data
          struct['data'] ||= {}
        end

        private

        def assign(attrs)
          attrs.stringify_keys!
          self.class.fields.each do |field|
            data[field] = attrs.delete(field) if attrs.include? field
          end

          super
        end
      end

      def fields
        @fields ||= []
      end

      private

      def field(*names)
        names.each do |name|
          name = name.to_s
          fields << name
          fields.uniq!

          define_method(name) { data[name] }
          define_method("#{name}=") { |value| data[name] = value }
        end
      end
    end

    module Timelines
      def timelines
        @timelines ||= []
      end

      def timeline(*names)
        args = names.last.is_a?(Hash) ? names.pop : {}

        names.each do |name|
          timeline_name = args[:internal] ? name.to_s : "timelines/#{name}"
          timelines << timeline_name
          timelines.uniq!

          define_method(name.to_s) { Fauna::Timeline.new("#{ref}/#{timeline_name}") }
        end
      end
    end

    module References
      def self.extended(base)
        base.send :include, InstanceMethods
      end

      module InstanceMethods
        def references
          struct['references'] ||= {}
        end

        private

        def assign(attrs)
          attrs.stringify_keys!
          self.class.references.each do |field|
            references[field] = attrs.delete(field).ref if attrs.include? field
            references[field] = attrs.delete("#{field}_ref") if attrs.include? "#{field}_ref"
          end

          super
        end
      end

      def references
        @references ||= []
      end

      def reference(*names)
        names.each do |name|
          name = name.to_s
          references << name
          references.uniq!

          define_method("#{name}_ref") { references[name] }
          define_method("#{name}_ref=") { |ref| references[name] = ref }

          define_method(name) { Fauna::Resource.find(references[name]) if references[name] }
          define_method("#{name}=") { |obj| references[name] = obj.ref }
        end
      end
    end
  end
end
