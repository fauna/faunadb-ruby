require File.expand_path('../test_helper', __FILE__)

class ConfigurationTest < MiniTest::Unit::TestCase
  def test_configuration
    Fauna.configure do |config|
      config.publisher_key = '1234567890abcdef'
    end

    assert_equal '1234567890abcdef', Fauna.configuration.publisher_key
  end
end
