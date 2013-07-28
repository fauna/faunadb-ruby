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

Fauna::Client.context(ROOT_CONNECTION) do
  Fauna::Database.new(:name => "fauna-ruby-test").delete rescue nil
  Fauna::Database.create(:name => "fauna-ruby-test")

  server_key = Fauna::Key.create("fauna-ruby-test", :role => "server")
  client_key = Fauna::Key.create("fauna-ruby-test", :role => "client")

  SERVER_CONNECTION = Fauna::Connection.new(:secret => server_key.secret, :domain => FAUNA_TEST_DOMAIN, :scheme => FAUNA_TEST_SCHEME)
  CLIENT_CONNECTION = Fauna::Connection.new(:secret => client_key.secret, :domain => FAUNA_TEST_DOMAIN, :scheme => FAUNA_TEST_SCHEME)
end

# fixtures

Fauna::Client.context(SERVER_CONNECTION) do
  Pig          = Fauna::Class.create :name => 'pigs'
  Pigkeeper    = Fauna::Class.create :name => 'pigkeepers'
  Vision       = Fauna::Class.create :name => 'visions'
  MessageBoard = Fauna::Class.create :name => 'message_boards'
  Post         = Fauna::Class.create :name => 'posts'
  Comment      = Fauna::Class.create :name => 'comments'
end

# test harness

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
