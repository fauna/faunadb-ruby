require 'json'
require 'logger'
require 'uri'
require 'typhoeus'
require 'cgi'
require 'zlib'

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
require 'fauna/cache'
require 'fauna/client'
require 'fauna/resource'
require 'fauna/named_resource'
require 'fauna/set'
