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

require "fauna/version"
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
