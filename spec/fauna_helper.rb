require 'fauna'
require 'securerandom'

FAUNA_ROOT_KEY = ENV['FAUNA_ROOT_KEY']
FAUNA_DOMAIN = ENV['FAUNA_DOMAIN']
FAUNA_SCHEME = ENV['FAUNA_SCHEME']
FAUNA_PORT = ENV['FAUNA_PORT']

module FaunaTestHelpers
  def get_client(params = {})
    params = { domain: FAUNA_DOMAIN, scheme: FAUNA_SCHEME, port: FAUNA_PORT }.merge(params)
    fail 'No secret provided' unless params.key? :secret
    Fauna::Client.new params
  end

  def root_client
    fail 'FAUNA_ROOT_KEY must be defined in your environment to run tests' unless FAUNA_ROOT_KEY
    get_client secret: FAUNA_ROOT_KEY
  end

  def client
    fail 'Server client not initialized' if @server_client.nil?
    @server_client
  end

  def create_test_db
    @db_ref = Fauna::Ref.new 'databases', "faunadb-ruby-test-#{random_string}"

    root = root_client
    root.query { create ref('databases'), name: @db_ref.id }

    begin
      server_key = root.query { create ref('keys'), database: @db_ref, role: 'server' }
    rescue
      root.query { delete @db_ref }
      @db_ref = nil
      raise
    end

    @server_secret = server_key[:secret]
    @server_client = get_client secret: @server_secret
  end

  def destroy_test_db
    root_client.query { delete @db_ref } unless @db_ref.nil?
  end

  def stub_client(method, url, response = nil, headers = {})
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.send(method, url) do |env|
      if response.nil?
        [200, headers, { resource: { method: env.method.to_s.upcase, body: JSON.load(env.body) } }.to_json]
      else
        [200, headers, response]
      end
    end
    Fauna::Client.new(adapter: [:test, stubs])
  end

  def random_string
    SecureRandom.hex(7)
  end

  def random_number
    SecureRandom.random_number(1_000_000)
  end

  def random_ref
    "classes/#{random_string}/#{random_number}"
  end

  def random_class_ref
    "classes/#{random_string}"
  end

  def to_json(value)
    Fauna::FaunaJson.to_json(value)
  end

  def from_json(value)
    Fauna::FaunaJson.json_load(value)
  end
end
