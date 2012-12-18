libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "rubygems"
gem "minitest"
require "fauna"
require "minitest/unit"
require "minitest/mock"
require "minitest/autorun"

class MiniTest::Unit::TestCase
  def parse_response(response)
    JSON.parse(response.to_str)
  end

  def fixture_data(fixture)
    return "" unless fixture
    File.open(File.join(File.dirname(__FILE__), "fixtures", "#{fixture}.json")).read
  end

  def fake_response(code, message, fixture_file)
    net_http_resp = Net::HTTPResponse.new(1.0, code, message)
    RestClient::Response.create(fixture_data(fixture_file), net_http_resp, nil)
  end

  def stub_response(*args, &block)
    if ENV["LIVE"] == 'true'
      block.call
    else
      RestClient.stub(*args, &block)
    end
  end

  def after_tests
    if ENV["LIVE"] == 'true'
      connection = Fauna::Connection.new
      connection.delete("everything", FAUNA_USERNAME, FAUNA_PASSWORD)
    end
  end
end

if ENV["LIVE"] == 'true'
  credentials_file = File.join(File.dirname(__FILE__), 'credentials.yml')
  if File.exists?(credentials_file)
    require 'yaml'
    credentials = YAML.load_file(credentials_file)
    FAUNA_USERNAME = credentials["username"]
    FAUNA_PASSWORD = credentials["password"]

    connection = Fauna::Connection.new

    connection.delete("everything", FAUNA_USERNAME, FAUNA_PASSWORD)
    response = connection.post("keys/publisher", {}, FAUNA_USERNAME, FAUNA_PASSWORD)
    publisher_key = JSON.parse(response)['resource']['key']
    Fauna.configure do |config|
      config.publisher_key = publisher_key
    end
  end
else
  Fauna.configure do |config|
    config.publisher_key = 'publisher_key'
  end
end
