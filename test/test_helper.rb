libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "rubygems"
require "test/unit"
require "fauna"
require "securerandom"
require "mocha/setup"

FAUNA_ROOT_KEY = ENV["FAUNA_ROOT_KEY"]
FAUNA_DOMAIN = ENV["FAUNA_DOMAIN"]
FAUNA_SCHEME = ENV["FAUNA_SCHEME"]
FAUNA_PORT = ENV["FAUNA_PORT"]

if !FAUNA_ROOT_KEY
  raise "FAUNA_ROOT_KEY must be defined in your environment to run tests."
end

ROOT_CONNECTION = Fauna::Connection.new(:secret => FAUNA_ROOT_KEY, :domain => FAUNA_DOMAIN, :scheme => FAUNA_SCHEME, :port => FAUNA_PORT)

Fauna::Client.context(ROOT_CONNECTION) do
  Fauna::Resource.new('databases', :name => "fauna-ruby-test").delete rescue nil
  Fauna::Resource.create 'databases', :name => "fauna-ruby-test"

  server_key = Fauna::Resource.create 'keys', :database => "databases/fauna-ruby-test", :role => "server"
  client_key = Fauna::Resource.create 'keys', :database => "databases/fauna-ruby-test", :role => "client"

  SERVER_CONNECTION = Fauna::Connection.new(:secret => server_key.secret, :domain => FAUNA_DOMAIN, :scheme => FAUNA_SCHEME, :port => FAUNA_PORT)
  CLIENT_CONNECTION = Fauna::Connection.new(:secret => client_key.secret, :domain => FAUNA_DOMAIN, :scheme => FAUNA_SCHEME, :port => FAUNA_PORT)
end

# fixtures

Fauna::Client.context(SERVER_CONNECTION) do
  Fauna::Resource.create 'classes', :name => 'pigs'
  Fauna::Resource.create 'classes', :name => 'pigkeepers'
  Fauna::Resource.create 'classes', :name => 'visions'
  Fauna::Resource.create 'classes', :name => 'message_boards'
  Fauna::Resource.create 'classes', :name => 'posts'
  Fauna::Resource.create 'classes', :name => 'comments'

  # Fixture for readme_test
  pig = Fauna::Resource.new('classes/pigs/42471470493859841')
  pig.ref = 'classes/pigs/42471470493859841'
  pig.class = 'classes/pigs'
  pig.save
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
