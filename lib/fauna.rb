require 'json'
require 'logger'
require 'uri'
require 'faraday'
require 'cgi'
require 'zlib'
require 'time'

##
# Main namespace for the FaunaDB client.
module Fauna; end

require 'fauna/version'
require 'fauna/json'
require 'fauna/util'
require 'fauna/errors'
require 'fauna/connection'
require 'fauna/client'
require 'fauna/client_logger'
require 'fauna/context'
require 'fauna/objects'
require 'fauna/query'
require 'fauna/request_result'
