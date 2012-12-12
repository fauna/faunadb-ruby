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
end
