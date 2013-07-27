require 'json'
require 'logger'
require 'uri'
require 'restclient'

if defined?(Rake)
  load "#{File.dirname(__FILE__)}/tasks/fauna.rake"
end

module Fauna
  class Invalid < RuntimeError
  end

  class NotFound < RuntimeError
  end
end

require 'fauna/util'
require 'fauna/connection'
require 'fauna/client'
require 'fauna/resource'
require 'fauna/set'
require 'fauna/provided_classes'
