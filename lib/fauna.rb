require "json"
require "logger"
require "uri"

require "restclient"
require "active_model"
require "active_support/inflector"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/slice"

if defined?(Rake)
  load "#{File.dirname(__FILE__)}/tasks/fauna.rake"
end

module Fauna
  class Invalid < RuntimeError
  end

  class NotFound < RuntimeError
  end

  class MissingMigration < RuntimeError
  end
end

require "fauna/connection"
require "fauna/client"
require "fauna/resource"
require "fauna/world"
require "fauna/event_set"
require "fauna/model"
require "fauna/model/class"
require "fauna/model/user"
require "fauna/ddl"

module Fauna
  DEFAULT_BLOCK = proc do
    with User, class_name: "users"
    with User::Config, class_name: "users/config"
    with EventsPage, class_name: "sets"
    with EventSetConfig, class_name: "sets/config"
    with ClassConfig, class_name: "classes/config"
    with Publisher, class_name: "world"
  end

  def self.configure_schema!
    @class_map = {}
    @schema = Fauna::DDL.new
    @blocks.each { |blk| @schema.instance_eval(&blk) }
    @schema.configure!
    nil
  end

  def self.schema(&block)
    @blocks << block
    configure_schema!
  end


  def self.reset_schema!
    @blocks = [DEFAULT_BLOCK]
    configure_schema!
  end

  def self.migrate_schema!
    @schema.load!
    nil
  end

  # these should be private to the gem

  def self.exists_class_for_name?(fauna_class)
    !!@class_map[fauna_class]
  end

  def self.add_class(fauna_class, klass)
    klass.fauna_class = fauna_class.to_s
    @class_map.delete_if { |_, v| v == klass }
    @class_map[fauna_class.to_s] = klass
  end

  def self.class_for_name(fauna_class)
    @class_map[fauna_class] ||=
    if fauna_class =~ %r{^classes/[^/]+$}
      klass = begin $1.classify.constantize rescue NameError; nil end
      if klass.nil? || klass >= Fauna::Class || klass.fauna_class # e.g. already associated with another fauna_class
        klass = ::Class.new(Fauna::Class)
      end

      klass.fauna_class = fauna_class
      klass
    else
      ::Class.new(Fauna::Resource)
    end
  end

  # apply the default schema so that the built-in classes work

  reset_schema!
end
