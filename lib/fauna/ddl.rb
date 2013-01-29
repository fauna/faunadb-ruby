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

    def resource(fauna_class_name, args = {})
      res = ResourceDDL.new(fauna_class_name, args)
      yield res if block_given?
      @ddls << res
      nil
    end

    class ResourceDDL
      def initialize(class_name, args = {})
        @timelines = []
        @class_name = class_name

        @class = args[:class] || gen_class(class_name)

        unless @class < max_super(class_name) || @class == max_super(class_name)
          raise ArgmentError "#{@class} must be a subclass of #{max_super}."
        end

        @meta = Fauna::ClassSettings.alloc('ref' => @class_name) if @class_name =~ %r{^classes/}
      end

      def configure!
        Fauna.instance_variable_get("@_classes")[@class_name] = @class if @class
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

      def gen_class(name)
        case name
        when "users" then Fauna::User
        when "publisher" then Fauna::Publisher
        when %r{^classes/[^/]+$} then ::Class.new(Fauna::Class)
        else Class.new(Fauna::Resource)
        end
      end
    end

    # timelines

    def timeline(name, args = {})
      @ddls << TimelineDDL.new(nil, name, args)
      nil
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
