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
    FIXTURES_DIR = "#{Rails.root}/test/fixtures/fauna"

    def self.auth!
      if File.exist? CONFIG_FILE
        credentials = YAML.load_file(CONFIG_FILE)[Rails.env] || {}

        if File.exist? LOCAL_CONFIG_FILE
          credentials.merge!((YAML.load_file(LOCAL_CONFIG_FILE)[APP_NAME] || {})[Rails.env] || {})
        end

        if !@silent
          if credentials["secret"]
            STDERR.puts ">> Using Fauna server key #{credentials["secret"].inspect} for #{APP_NAME.inspect}."
          else
            STDERR.puts ">> Using Fauna account #{credentials["email"].inspect} for #{APP_NAME.inspect}."
          end

          STDERR.puts ">> You can change this in config/fauna.yml or ~/.fauna.yml."
        end

        if credentials["secret"]
          secret = credentials["secret"]
        else
          self.root_connection = Connection.new(
            :email => credentials["email"],
            :password => credentials["password"],
          :logger => Rails.logger)

          secret = root_connection.post("keys", "role" => "server")["resource"]["key"]
        end

        self.connection = Connection.new(secret: secret, logger: Rails.logger)
      else
        if !@silent
          STDERR.puts ">> Fauna account not configured. You can add one in config/fauna.yml."
        end
      end

      @silent = true
      nil
    end

    # Around filter to set up a default context

    # ActionDispatch's Auto reloader blows away some of Fauna's schema
    # configuration that does not live within the Model classes
    # themselves. Add a callback to Reloader to reload the schema config
    # before each request.
    def self.install_around_filter!
      if Fauna.connection && defined?(ActionController::Base)
        ApplicationController.class_eval do
          around_filter :default_fauna_context

          def default_fauna_context
            Fauna::Client.context(Fauna.connection) { yield }
          end
        end
      end
    end

    def self.install_reload_callback!
      if defined? ActionDispatch::Reloader
        ActionDispatch::Reloader.to_prepare do
          Fauna.install_around_filter!
        end
      end
    end

    def self.install_inflections!
      # ActiveSupport::Inflector's 'humanize' method handles the _id
      # suffix for association fields, but not _ref.
      if defined? ActiveSupport::Inflector
        ActiveSupport::Inflector.inflections do |inflect|
          inflect.human /_ref$/i, ''
        end
      end
    end

    def self.install_test_helper!
      if defined? ActiveSupport::TestCase
        ActiveSupport::TestCase.setup do
          Fauna::Client.push_context(Fauna.connection)
        end

        ActiveSupport::TestCase.teardown do
          Fauna::Client.pop_context
        end
      end
    end

    def self.install_console_helper!
      Rails.application.class.console do
        Fauna::Client.push_context(Fauna.connection)
      end
    end
  end

  Fauna.auth!
  Fauna.install_around_filter!
  Fauna.install_reload_callback!
  Fauna.install_inflections!
  Fauna.install_test_helper!
  Fauna.install_console_helper!
end
