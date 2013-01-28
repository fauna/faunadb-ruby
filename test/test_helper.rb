libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "rubygems"
require "test/unit"
require "fauna"
require "securerandom"
require "mocha/setup"

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


class Pig < Fauna::Class
  field :name, :visited
  timeline :visions
end

class Pigkeeper < Fauna::Class
  field :visited, :pockets

  validates :visited, :presence => true
  validate :pockets_are_full

  def pockets_are_full
    errors.add :pockets, 'must be full of piggy treats' if pockets <= 0 unless pockets.blank?
  end
end

class Vision < Fauna::Class
  field :text
  reference :pig
end

class MiniTest::Unit::TestCase
  def setup
    @root_connection = ROOT_CONNECTION
    @publisher_connection = PUBLISHER_CONNECTION
    @client_connection = CLIENT_CONNECTION
    Fauna::Client.push_context(@publisher_connection)
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
