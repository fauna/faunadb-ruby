require "json"
require "logger"
require "ostruct"

require "rubygems"
require "restclient"
require "active_model"
require "active_support/inflector"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/slice"

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

module Fauna
end
