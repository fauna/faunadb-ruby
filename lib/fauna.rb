require 'json'
require 'logger'
require 'uri'
require 'faraday'
require 'cgi'
require 'zlib'

##
# Main namespace for the FaunaDB client.
module Fauna; end

require 'fauna/util'
require 'fauna/errors'
require 'fauna/connection'
require 'fauna/client'
require 'fauna/context'
require 'fauna/objects'
require 'fauna/query'
