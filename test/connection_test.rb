require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < MiniTest::Unit::TestCase
  def setup
    @connection = Fauna::Connection.new(:publisher_key => 'dummy')
  end

  def test_get
    response = parse_response(@connection.get("users"))
    assert_equal "https://dummy:@rest.fauna.org/v0/users", @connection.url("users", :publisher)
    assert_equal "users/20146146758361088", response["resources"][0]["ref"]
    assert_equal 1356034095215847, response["resources"][0]["ts"]
    assert_equal "Taran", response["resources"][0]["name"]
  end

  def test_get_with_invalid_key
    connection = Fauna::Connection.new(:publisher_key => 'bad_key')
    response = parse_response(connection.get("users"))
    assert_equal "https://bad_key:@rest.fauna.org/v0/users", connection.url("users", :publisher)
    assert_equal "Unauthorized", response["error"]
  end

  def test_post
    attributes = { "name" => "Taran", "email" => "taran@example.com",
                   "password" => "tnT8m&vwm" }
    response = parse_response(@connection.post("users", attributes))
    assert_equal "https://dummy:@rest.fauna.org/v0/users", @connection.url("users", :publisher)
    assert_equal "users/20146146758361088", response["resource"]["ref"]
    assert_equal 1355204292824057, response["resource"]["ts"]
  end

  def test_put
    response = parse_response(@connection.put("users/19865736628404225", {:data => {:pockets => 2}}))
    expected_url = "https://dummy:@rest.fauna.org/v0/users/19865736628404225"
    assert_equal expected_url, @connection.url("users/19865736628404225", :publisher)
    assert_equal "users/19865736628404225", response["resource"]["ref"]
    assert_equal 1355204297083014, response["resource"]["ts"]
    assert_equal 2, response["resource"]["data"]["pockets"]
  end

  def test_delete
    response = @connection.delete("users/19865736628404225")
    expected_url = "https://dummy:@rest.fauna.org/v0/users/19865736628404225"
    assert_equal expected_url, @connection.url("users/19865736628404225", :publisher)
    assert_equal "", response
  end
end
