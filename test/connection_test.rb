require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < MiniTest::Unit::TestCase
  def test_get
    @publisher_connection.get("users")
  end

  def test_get_with_invalid_key
    connection = Fauna::Connection.new(:publisher_key => 'bad_key')
    assert_raises(Fauna::Connection::Unauthorized) do
      connection.get("users")
    end
  end

  def test_post
    attributes = { "name" => "Taran", "email" => email, "password" => password }
    user = @client_connection.post("users", attributes)['resource']
  end

  def test_put
    attributes = { "name" => "Taran", "email" => email, "password" => password }
    user = @publisher_connection.post("users", attributes)['resource']
    user = @publisher_connection.put(user['ref'], {:data => {:pockets => 2}})['resource']
    assert_equal 2, user['data']['pockets']
  end

  def test_delete
    attributes = { "name" => "Taran", "email" => email, "password" => password }
    user = @publisher_connection.post("users", attributes)['resource']
    @publisher_connection.delete(user['ref'])
    assert_raises(Fauna::Connection::NotFound) do
      @publisher_connection.get(user['ref'])
    end
  end
end
