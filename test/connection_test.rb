require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < MiniTest::Unit::TestCase
  def setup
    super
    @attributes = { "name" => "Arawn", "email" => email, "password" => password }
  end

  def test_get
    @world_connection.get("users")
  end

  def test_get_with_invalid_key
    connection = Fauna::Connection.new(:server_key => 'bad_key')
    assert_raises(Fauna::Connection::Unauthorized) do
      connection.get("users")
    end
  end

  def test_post
    @client_connection.post("users", @attributes)['resource']
  end

  def test_put
    user = @world_connection.post("users", @attributes)['resource']
    user = @world_connection.put(user['ref'], {:data => {:pockets => 2}})['resource']
    assert_equal 2, user['data']['pockets']
  end

  def test_delete
    user = @world_connection.post("users", @attributes)['resource']
    @world_connection.delete(user['ref'])
    assert_raises(Fauna::Connection::NotFound) do
      @world_connection.get(user['ref'])
    end
  end
end
