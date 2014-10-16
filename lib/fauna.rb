require 'json'
require 'logger'
require 'uri'
require 'faraday'
require 'cgi'
require 'zlib'

load "#{File.dirname(__FILE__)}/tasks/fauna.rake" if defined?(Rake)

module Fauna
  class Invalid < RuntimeError
  end

  class NotFound < RuntimeError
  end
end

require 'fauna/util'
require 'fauna/connection'
require 'fauna/cache'
require 'fauna/client'
require 'fauna/resource'
require 'fauna/named_resource'
require 'fauna/set'
