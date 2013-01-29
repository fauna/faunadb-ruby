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

  @_classes = DEFAULT_CLASSES

  def self.schema
    @schema = Fauna::DDL.new
    yield @schema
    @_classes = DEFAULT_CLASSES.dup
    @schema.configure!
    nil
  end

  def self.load_schema!
    @schema.load!
    nil
  end

  def self.class_for_name(class_name)
    @_classes[class_name] ||=
      if class_name =~ %r{^classes/[^/]+$}
        klass = begin $1.camelcase.constantize rescue NameError; nil end
        if klass.nil? || klass >= Fauna::Class || klass.fauna_class
          klass = ::Class.new(Fauna::Class)
        end

        klass.fauna_class = class_name
        klass
      else
        ::Class.new(Fauna::Resource)
      end
  end
end
