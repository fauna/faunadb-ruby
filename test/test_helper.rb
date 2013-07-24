libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "rubygems"
require "test/unit"
require "fauna"
require "securerandom"
require "mocha/setup"

FAUNA_TEST_ROOTKEY = ENV["FAUNA_TEST_ROOTKEY"]
FAUNA_TEST_DOMAIN = ENV["FAUNA_TEST_DOMAIN"]

if !(FAUNA_TEST_ROOTKEY && FAUNA_TEST_DOMAIN)
  raise "FAUNA_TEST_ROOTKEY and FAUNA_TEST_DOMAIN must be defined in your environment to run tests."
end

ROOT_CONNECTION = Fauna::Connection.new(:root_key => FAUNA_TEST_ROOTKEY, :domain => FAUNA_TEST_DOMAIN)

world = "worlds/fauna-ruby-test"

ROOT_CONNECTION.delete(world) rescue nil
ROOT_CONNECTION.put(world)

key = ROOT_CONNECTION.post("#{world}/keys/server")['resource']['key']
SERVER_CONNECTION = Fauna::Connection.new(:server_key => key)

key = ROOT_CONNECTION.post("#{world}/keys/client")['resource']['key']
CLIENT_CONNECTION = Fauna::Connection.new(:client_key => key)

load "#{File.dirname(__FILE__)}/fixtures.rb"

Fauna::Client.context(SERVER_CONNECTION) do
  Fauna.migrate_schema!
end

class MiniTest::Unit::TestCase
  def setup
    @root_connection = ROOT_CONNECTION
    @server_connection = SERVER_CONNECTION
    @client_connection = CLIENT_CONNECTION
    Fauna::Client.push_context(@server_connection)
  end

  def teardown
    Fauna::Client.pop_context
  end

  def email
    "#{SecureRandom.random_number}@example.com"
  end

  def fail
    assert false, "Not implemented"
  end

  def pass
    assert true
  end

  def password
    SecureRandom.random_number.to_s
  end
end
