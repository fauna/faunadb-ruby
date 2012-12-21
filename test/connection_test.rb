require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < MiniTest::Unit::TestCase
  def setup
    @connection = Fauna::Connection.new(:publisher_key => 'dummy')
  end

  def test_get
    RestClient.stub(:get, fake_response(200, "OK", "users")) do
      response = parse_response(@connection.get("users"))
      ref = response["references"].keys.first

      assert_equal "https://dummy:@rest.fauna.org/v0/users", @connection.url("users", :publisher)
      assert_equal "users/20146146758361088", response["references"][ref]["ref"]
      assert_equal 1355471712739180, response["references"][ref]["ts"]
      assert_equal "Taran", response["references"][ref]["name"]
    end
  end

  def test_get_with_invalid_key
    RestClient.stub(:get, fake_response(401, "Unauthorized", "invalid")) do
      connection = Fauna::Connection.new(:publisher_key => 'bad_key')
      response = parse_response(connection.get("users"))

      assert_equal "https://bad_key:@rest.fauna.org/v0/users", connection.url("users", :publisher)
      assert_equal "Unauthorized", response["error"]
    end
  end

  def test_post
    RestClient.stub(:post, fake_response(201, "Created", "user")) do
      attributes = { "name" => "Taran", "email" => "taran@example.com",
                     "password" => "tnT8m&vwm" }
      response = parse_response(@connection.post("users", attributes))

      assert_equal "https://dummy:@rest.fauna.org/v0/users", @connection.url("users", :publisher)
      assert_equal "users/19865736628404225", response["resource"]["ref"]
      assert_equal 1355204292824057, response["resource"]["ts"]
    end
  end

  def test_put
    RestClient.stub(:put, fake_response(200, "OK", "user_with_pockets")) do
      response = parse_response(@connection.put("users/19865736628404225", {:data => {:pockets => 2}}))

      expected_url = "https://dummy:@rest.fauna.org/v0/users/19865736628404225"
      assert_equal expected_url, @connection.url("users/19865736628404225", :publisher)
      assert_equal "users/19865736628404225", response["resource"]["ref"]
      assert_equal 1355204297083014, response["resource"]["ts"]
      assert_equal 2, response["resource"]["data"]["pockets"]
    end
  end

  def test_delete
    RestClient::Request.stub(:execute, fake_response(204, "No Content", nil)) do
      response = @connection.delete("users/19865736628404225")

      expected_url = "https://dummy:@rest.fauna.org/v0/users/19865736628404225"
      assert_equal expected_url, @connection.url("users/19865736628404225", :publisher)
      assert_equal "", response
    end
  end
end
