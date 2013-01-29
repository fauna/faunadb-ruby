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
      args.stringify_keys!

      res = ResourceDDL.new(fauna_class_name)
      res.class = args['class'] if args['class']

      yield res if block_given?
      @ddls << res

      nil
    end

    class ResourceDDL
      def initialize(class_name)
        @class = nil
        @timelines = []
        @class_name = class_name
        @meta = Fauna::Class::Meta.alloc('ref' => @class_name) if @class_name =~ %r{^classes/}
      end

      def configure!
        Fauna.instance_variable_get("@_classes")[@class_name] = @class if @class
      end

      def load!
        @meta.save! if @meta
        @timelines.each { |t| t.load! }
      end

      def class=(klass)
        max_super = case @class_name
                    when "users" then Fauna::User
                    when %r{^classes/[^/]+$} then Fauna::Class
                    else Fauna::Resource
                    end

        unless klass < max_super || klass == max_super
          raise ArgmentError "#{klass} must be a subclass of #{max_super}."
        end

        @class = klass
      end

      def timeline(name, args = {})
        @timelines << TimelineDDL.new(@class_name, name, args)
      end

      def field(name)
      end

      def reference(name)
      end
    end

    # timelines

    def timeline(name, args = {})
      @ddls << TimelineDDL.new(nil, name, args)

      nil
    end

    class TimelineDDL
      def initialize(parent_class, name, args)
        args.stringify_keys!

        @parent_class = parent_class
        @name = name
        @args = args
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
