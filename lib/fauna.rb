require 'json'
require 'logger'
require 'uri'
require 'faraday'
require 'cgi'
require 'zlib'
require 'time'
require 'base64'

##
# Main namespace for the FaunaDB driver.
module Fauna; end

require 'fauna/deprecate'
require 'fauna/version'
require 'fauna/util'
require 'fauna/errors'
require 'fauna/client'
require 'fauna/client_logger'
require 'fauna/context'
require 'fauna/objects'
require 'fauna/query'
require 'fauna/json'
require 'fauna/page'
require 'fauna/request_result'
