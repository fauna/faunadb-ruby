libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter 'test/'
end

require 'rubygems'
require 'minitest/autorun'
require 'fauna'
require 'securerandom'

FAUNA_ROOT_KEY = ENV['FAUNA_ROOT_KEY']
FAUNA_DOMAIN = ENV['FAUNA_DOMAIN']
FAUNA_SCHEME = ENV['FAUNA_SCHEME']
FAUNA_PORT = ENV['FAUNA_PORT']

unless FAUNA_ROOT_KEY
  fail 'FAUNA_ROOT_KEY must be defined in your environment to run tests.'
end

class FaunaTest < MiniTest::Test
  include Fauna

  attr_reader :db_ref
  attr_reader :root_client

  def setup
    @db_ref = Ref.new 'databases', "faunadb-ruby-test-#{RandomHelper.random_string}"

    @root_client = get_client secret: FAUNA_ROOT_KEY

    @root_client.query Query.create(Ref.new('databases'), Query.object(name: db_ref.id))

    server_key = @root_client.query Query.create(Ref.new('keys'), Query.object(database: db_ref, role: 'server'))
    @server_secret = server_key[:secret]
    @server_client = get_client
  end

  def teardown
    @root_client.query Query.delete(db_ref)
  end

  def client
    @server_client
  end

  def get_client(params = {})
    defaults = { domain: FAUNA_DOMAIN, scheme: FAUNA_SCHEME, port: FAUNA_PORT, secret: @server_secret }
    Client.new defaults.merge(params)
  end

protected

  def stub_client(method, url, response, params = {})
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.send(method, url) do
      response
    end
    Client.new({ adapter: [:test, stubs] }.merge params)
  end
end

module RandomHelper
  def self.random_string
    SecureRandom.hex(7)
  end

  def self.random_number
    SecureRandom.random_number(1_000_000)
  end
end
