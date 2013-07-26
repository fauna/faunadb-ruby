libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "rubygems"
require "test/unit"
require "fauna"
require "securerandom"
require "mocha/setup"

FAUNA_TEST_ROOTKEY = ENV["FAUNA_TEST_ROOTKEY"]
FAUNA_TEST_DOMAIN = ENV["FAUNA_TEST_DOMAIN"]
FAUNA_TEST_SCHEME = ENV["FAUNA_TEST_SCHEME"]

if !(FAUNA_TEST_ROOTKEY && FAUNA_TEST_DOMAIN && FAUNA_TEST_SCHEME)
  raise "FAUNA_TEST_ROOTKEY, FAUNA_TEST_DOMAIN and FAUNA_TEST_SCHEME must be defined in your environment to run tests."
end

ROOT_CONNECTION = Fauna::Connection.new(:secret => FAUNA_TEST_ROOTKEY, :domain => FAUNA_TEST_DOMAIN, :scheme => FAUNA_TEST_SCHEME)

database = "databases/fauna-ruby-test"

ROOT_CONNECTION.delete(database) rescue nil
ROOT_CONNECTION.put(database)

key = ROOT_CONNECTION.post("#{database}/keys", "role" => "server")['resource']['secret']
SERVER_CONNECTION = Fauna::Connection.new(:secret => key, :domain => FAUNA_TEST_DOMAIN, :scheme => FAUNA_TEST_SCHEME)

key = ROOT_CONNECTION.post("#{database}/keys", "role" => "client")['resource']['secret']
CLIENT_CONNECTION = Fauna::Connection.new(:secret => key, :domain => FAUNA_TEST_DOMAIN, :scheme => FAUNA_TEST_SCHEME)

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
