module Fauna
  class DDL

    def initialize
      @ddls = []
    end

    def configure!
      @ddls.each { |ddl| ddl.configure! }
    end

    def load!
      @ddls.each { |ddl| ddl.load! }
    end

    # resources

    def with(klass, args = {}, &block)
      res = ResourceDDL.new(klass, args)
      res.instance_eval(&block) if block_given?
      @ddls << res
      nil
    end

    class ResourceDDL
      def initialize(klass, args = {})
        @event_sets = []
        @class = klass
        @fauna_class = args[:class_name] || derived_fauna_class(@class)

        unless @class <= max_super(@fauna_class)
          raise ArgumentError, "#{@class} must be a subclass of #{max_super(@fauna_class)}."
        end

        if @fauna_class =~ %r{^classes/[^/]+$} && @fauna_class != 'classes/config'
          @meta = Fauna::ClassConfig.alloc('ref' => "#{@fauna_class}/config")
        end
      end

      def configure!
        Fauna.add_class(@fauna_class, @class) if @class
      end

      def load!
        @meta.save! if @meta
        @event_sets.each { |t| t.load! }
      end

      def event_set(*name)
        args = name.last.is_a?(Hash) ? name.pop : {}
        @class.send :event_set, *name

        name.each { |n| @event_sets << EventSetDDL.new(@fauna_class, n, args) }
      end

      def field(*name)
        @class.send :field, *name
      end

      def reference(*name)
        @class.send :reference, *name
      end

      private

      def max_super(name)
        case name
        when "users" then Fauna::User
        when "publisher" then Fauna::Publisher
        when "classes/config" then Fauna::Resource
        when %r{^classes/[^/]+$} then Fauna::Class
        else Fauna::Resource
        end
      end

      def derived_fauna_class(klass)
        if klass < Fauna::User
          "users"
        elsif klass < Fauna::Publisher
          "publisher"
        elsif  klass < Fauna::Class
          "classes/#{klass.name.tableize}"
        else
          raise ArgumentError, "Must specify a :class_name for non-default resource class #{klass.name}"
        end
      end
    end

    # event_sets

    class EventSetDDL
      def initialize(parent_class, name, args)
        @meta = EventSetConfig.new(parent_class, name, args)
      end

      def configure!
      end

      def load!
        @meta.save!
      end
    end

    # commands

    # def command(name)
    #   cmd = CommandDDL.new(name)

    #   yield cmd
    #   @ddls << cmd

    #   nil
    # end

    # class CommandDDL
    #   attr_accessor :comment

    #   def initialize(name)
    #     @actions = []
    #   end

    #   def configure!
    #   end

    #   def load!
    #   end

    #   def get(path, args = {})
    #     args.update method: 'GET', path: path
    #     args.stringify_keys!

    #     @actions << args
    #   end
    # end
  end

  # c.command "name" do |cmd|
  #   cmd.comment = "foo bar"

  #   cmd.get "users/self", :actor => "blah", :body => {}
  # end
end
