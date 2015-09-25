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

class FaunaTest < Test::Unit::TestCase
  def setup
    @root_client = get_client secret: FAUNA_ROOT_KEY

    begin
      @root_client.delete db_ref
    rescue Fauna::NotFound
    end
    @root_client.post 'databases', name: 'fauna-ruby-test'

    server_key = @root_client.post 'keys', database: db_ref, role: 'server'
    @server_client = get_client secret: server_key['secret']
  end

  def teardown
    @root_client.delete db_ref
  end

  def db_ref
    Fauna::Ref.new 'databases/fauna-ruby-test'
  end

  def client
    @server_client
  end

  def get_client(params = {})
    all_params = { domain: FAUNA_DOMAIN, scheme: FAUNA_SCHEME, port: FAUNA_PORT }.merge(params)
    Fauna::Client.new all_params
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
