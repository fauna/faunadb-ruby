require 'fauna'

# Various and sundry Rails integration points

if defined?(Rails)
  module Fauna
    mattr_accessor :root_connection
    mattr_accessor :connection

    @silent = false

    CONFIG_FILE = "#{Rails.root}/config/fauna.yml"
    LOCAL_CONFIG_FILE = "#{ENV["HOME"]}/.fauna.yml"
    APP_NAME = Rails.application.class.name.split("::").first.underscore

    def self.auth!
      if File.exist? CONFIG_FILE
        credentials = YAML.load_file(CONFIG_FILE)[Rails.env] || {}

        if File.exist? LOCAL_CONFIG_FILE
          credentials.merge!((YAML.load_file(LOCAL_CONFIG_FILE)[APP_NAME] || {})[Rails.env] || {})
        end

        if !@silent
          STDERR.puts ">> Using Fauna account #{credentials["email"].inspect} for #{APP_NAME.inspect}."
          STDERR.puts ">> You can change this in config/fauna.yml or ~/.fauna.yml."
        end

        self.root_connection = Connection.new(
          :email => credentials["email"],
          :password => credentials["password"],
        :logger => Rails.logger)

        publisher_key = root_connection.post("keys/publisher")["resource"]["key"]
        self.connection = Connection.new(publisher_key: publisher_key, logger: Rails.logger)
      else
        if !@silent
          STDERR.puts ">> Fauna account not configured. You can add one in config/fauna.yml."
        end
      end

      @silent = true
      nil
    end
  end

  Fauna.auth!

  # Around filter to set up a default context

  if Fauna.connection && defined?(ActionController::Base)
    ApplicationController

    class ApplicationController
      around_filter :default_fauna_context

      def default_fauna_context
        Fauna::Client.context(Fauna.connection) { yield }
      end
    end
  end

  # ActionDispatch's Auto reloader blows away some of Fauna's schema
  # configuration that does not live within the Model classes
  # themselves. Add a callback to Reloader to reload the schema config
  # before each request.

  if defined? ActionDispatch::Reloader
    ActionDispatch::Reloader.to_prepare do
      Fauna.configure_schema!
    end
  end

  # ActiveSupport::Inflector's 'humanize' method handles the _id
  # suffix for association fields, but not _ref.
  if defined? ActiveSupport::Inflector
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.human /_ref$/i, ''
    end
  end
end
