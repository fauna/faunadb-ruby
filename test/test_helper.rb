libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "test/unit"
require "fauna"
require "securerandom"

FAUNA_TEST_USERNAME = ENV["FAUNA_TEST_USERNAME"]
FAUNA_TEST_PASSWORD = ENV["FAUNA_TEST_PASSWORD"]

class Test::Unit::TestCase
  module Helpers
    def parse_response(response)
      JSON.parse(response.to_str)
    end

    def before_tests
      @root_connection = Fauna::Connection.new(:username => FAUNA_TEST_USERNAME, :password => FAUNA_TEST_PASSWORD)
      @root_connection.delete("everything")

      key = parse_response(@root_connection.post("keys/publisher"))['resource']['key']
      @publisher_connection = Fauna::Connection.new(:publisher_key => key)

      key = parse_response(@root_connection.post("keys/client"))['resource']['key']
      @client_connection = Fauna::Connection.new(:client_key => key)
    end
  end

  include Helpers
  extend Helpers
end
