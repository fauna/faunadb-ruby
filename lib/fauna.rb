require "json"
require "logger"

require "restclient"
require "active_model"
require "active_support/inflector"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/slice"

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
require "fauna/model"
require "fauna/model/class"
require "fauna/model/follow"
require "fauna/model/publisher"
require "fauna/model/timeline"
require "fauna/model/user"
require "fauna/ddl"

module Fauna

  DEFAULT_CLASSES = {
    "users" => Fauna::User,
    "follows" => Fauna::Follow,
    "timelines" => Fauna::TimelinePage,
    "timelines/settings" => Fauna::TimelineSettings,
    "classes" => Fauna::ClassSettings,
    "publisher" => Fauna::Publisher
  }

  @_classes = DEFAULT_CLASSES.dup
  @_blocks = []

  def self.configure_schema!
    @_classes = DEFAULT_CLASSES.dup
    @schema = Fauna::DDL.new
    @_blocks.each { |blk| @schema.instance_eval(&blk) }
    @schema.configure!
    nil
  end

  def self.schema(&block)
    @_blocks << block
    configure_schema!
  end


  def self.reset_schema!
    @_blocks = []
    configure_schema!
  end

  def self.migrate_schema!
    @schema.load!
    nil
  end

  # these should be private to the gem

  def self.exists_class_for_name?(class_name)
    !!@_classes[class_name]
  end

  def self.add_class(class_name, klass)
    klass.fauna_class_name = class_name.to_s
    @_classes.delete_if { |_, v| v == klass }
    @_classes[class_name.to_s] = klass
  end

  def self.class_for_name(class_name)
    @_classes[class_name] ||=
    if class_name =~ %r{^classes/[^/]+$}
      klass = begin $1.classify.constantize rescue NameError; nil end
      if klass.nil? || klass >= Fauna::Class || klass.fauna_class_name
        klass = ::Class.new(Fauna::Class)
      end

      klass.fauna_class_name = class_name
      klass
    else
      ::Class.new(Fauna::Resource)
    end
  end
end
