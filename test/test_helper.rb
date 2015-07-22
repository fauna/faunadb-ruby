libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require 'rubygems'
require 'test/unit'
require 'fauna'
require 'securerandom'
require 'mocha/setup'

FAUNA_ROOT_KEY = ENV['FAUNA_ROOT_KEY']
FAUNA_DOMAIN = ENV['FAUNA_DOMAIN']
FAUNA_SCHEME = ENV['FAUNA_SCHEME']
FAUNA_PORT = ENV['FAUNA_PORT']

unless FAUNA_ROOT_KEY
  fail 'FAUNA_ROOT_KEY must be defined in your environment to run tests.'
end

ROOT_CLIENT = Fauna::Client.new(secret: FAUNA_ROOT_KEY, domain: FAUNA_DOMAIN, scheme: FAUNA_SCHEME, port: FAUNA_PORT)

# Create server client

test_db = Fauna::Ref.new('databases/fauna-ruby-test')

begin
  ROOT_CLIENT.query(Fauna::Query.delete(test_db))
rescue Fauna::NotFound
end
ROOT_CLIENT.query(Fauna::Query.create(test_db.to_class, Fauna::Query.quote('name' => 'fauna-ruby-test')))

server_key = ROOT_CLIENT.query(Fauna::Query.create(Fauna::Ref.new('keys'), Fauna::Query.quote('database' => test_db, 'role' => 'server')))

SERVER_CLIENT = Fauna::Connection.new(secret: server_key['resource']['secret'], domain: FAUNA_DOMAIN, scheme: FAUNA_SCHEME, port: FAUNA_PORT)

# Test harness
module MiniTest
  class Unit
    class TestCase
      def setup
        @root_client = ROOT_CLIENT
        @server_client = SERVER_CLIENT
        @stubs = Faraday::Adapter::Test::Stubs.new
        @test_headers = {
          'X-FaunaDB-Build' => 'FAKE',
          'X-FaunaDB-Host' => 'FAKE',
          'X-HTTP-Request-Processing-Time' => '1',
        }
        @test_client = Fauna::Client.new(adapter: [:test, @stubs])
        @test_connection = Fauna::Connection.new(adapter: [:test, @stubs])
      end
    end
  end
end

module RandomHelper
  def self.random_string
    SecureRandom.hex(7)
  end

  def self.random_number
    SecureRandom.random_number(1_000_000)
  end

  def self.random_email
    SecureRandom.hex(5) + '@example.org'
  end
end
