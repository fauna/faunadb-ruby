module Fauna
  class Model
    module Fields
      private

      def self.extended(base)
        base.send :resource_accessor, :data
        (class << base; self; end).send :attr_accessor, :fields
      end

      def field(*names)
        names.each do |name|
          name = name.to_s

          assignable_field name
          (@fields ||= []) << name

          define_method(name) { (self.data ||= {})[name] }
          define_method("#{name}=") { |value| (self.data ||= {})[name] = value }
        end
      end
    end

    module Timelines
      private

      def self.extended(base)
        (class << base; self; end).send :attr_accessor, :timelines
      end

      def timeline(*names)
        args = names.last.is_a?(Hash) ? names.pop : {}

        names.each do |name|
          timeline_name = args[:internal] ? name.to_s : "timelines/#{name}"
          timeline_ref = "#{ref}/#{timeline_name}"
          (@timelines ||= []) << timeline_name

          define_method(timeline_name) { Fauna::Timeline.new(timeline_ref) }
        end
      end
    end

    module References
      private

      def self.extended(base)
        base.send :resource_accessor, :references
        (class << base; self; end).send :attr_accessor, :references
      end

      def reference(*names)
        names.each do |name|
          name = name.to_s
          ref_name = "#{name}_ref"

          assignable_field name, ref_name

          (@references ||= []) << name << ref_name

          define_method(ref_name) { references[name] }
          define_method("#{ref_name}=") { |ref| references[name] = ref }

          define_method(name) { Fauna::Client.find(references[name]) if references[name] }
          define_method("#{name}=") { |obj| references[name] = obj.ref }
        end
      end
    end
  end
end
