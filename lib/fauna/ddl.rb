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

    def with(__class__, args = {}, &block)
      res = ResourceDDL.new(__class__, args)
      res.instance_eval(&block) if block_given?
      @ddls << res
      nil
    end

    class ResourceDDL
      def initialize(__class__, args = {})
        @timelines = []
        @class = __class__
        @class_name = args[:class_name] || fauna_class_name_name(@class)
        @class.fauna_class_name = @class_name

        unless @class <= max_super(@class_name)
          raise ArgmentError "#{@class} must be a subclass of #{max_super(@class_name)}."
        end

        @meta = Fauna::ClassSettings.alloc('ref' => @class_name) if @class_name =~ %r{^classes/[^/]+$}
      end

      def configure!
        Fauna.add_class(@class_name, @class) if @class
      end

      def load!
        @meta.save! if @meta
        @timelines.each { |t| t.load! }
      end

      def timeline(*name)
        args = name.last.is_a?(Hash) ? name.pop : {}
        @class.send :timeline, *name

        name.each { |n| @timelines << TimelineDDL.new(@class_name, n, args) }
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
        when %r{^classes/[^/]+$} then Fauna::Class
        else Fauna::Resource
        end
      end

      def fauna_class_name_name(__class__)
        if __class__ < Fauna::User
          "users"
        elsif __class__ < Fauna::Publisher
          "publisher"
        elsif  __class__ < Fauna::Class
          "classes/#{__class__.name.tableize}"
        else
          raise ArgumentError, "Must specify a :class_name for non-default resource class #{__class__.name}"
        end
      end
    end

    # timelines

    def timeline(*name)
      args = name.last.is_a?(Hash) ? name.pop : {}
      name.each { |n| @ddls << TimelineDDL.new(nil, n, args) }
    end

    class TimelineDDL
      def initialize(parent_class, name, args)
        @meta = TimelineSettings.new(name, args)
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
