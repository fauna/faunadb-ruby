libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "test/unit"
require "fauna"
require "securerandom"

FAUNA_TEST_EMAIL = ENV["FAUNA_TEST_EMAIL"]
FAUNA_TEST_PASSWORD = ENV["FAUNA_TEST_PASSWORD"]

if !(FAUNA_TEST_PASSWORD && FAUNA_TEST_PASSWORD)
  raise "FAUNA_TEST_EMAIL and FAUNA_TEST_PASSWORD must be defined in your environment to run tests."
end

ROOT_CONNECTION = Fauna::Connection.new(:email => FAUNA_TEST_EMAIL, :password => FAUNA_TEST_PASSWORD)
ROOT_CONNECTION.delete("everything")

key = ROOT_CONNECTION.post("keys/publisher")['resource']['key']
PUBLISHER_CONNECTION = Fauna::Connection.new(:publisher_key => key)

key = ROOT_CONNECTION.post("keys/client")['resource']['key']
CLIENT_CONNECTION = Fauna::Connection.new(:client_key => key)

class MiniTest::Unit::TestCase
  def setup
    @root_connection = ROOT_CONNECTION
    @publisher_connection = PUBLISHER_CONNECTION
    @client_connection = CLIENT_CONNECTION
  end

  def email
    "#{SecureRandom.random_number}@example.com"
  end

  def password
    SecureRandom.random_number.to_s
  end
end
