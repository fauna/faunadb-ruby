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
require "fauna/mixins"
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
    "classes" => Fauna::Class::Meta,
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
end
