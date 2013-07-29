require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < MiniTest::Unit::TestCase
  def setup
    super
    @attributes = { "name" => "Arawn", "email" => email, "password" => password }
  end

  def test_get
    @server_connection.get("users/instances")
  end

  def test_get_with_invalid_key
    connection = Fauna::Connection.new(:secret => 'bad_key', :domain => @server_connection.domain, :scheme => @server_connection.scheme)
    assert_raises(Fauna::Connection::Unauthorized) do
      connection.get("users/instances")
    end
  end

  def test_post
    @client_connection.post("users", @attributes)['resource']
  end

  def test_put
    user = @server_connection.post("users", @attributes)['resource']
    user = @server_connection.put(user['ref'], {:data => {:pockets => 2}})['resource']
    assert_equal 2, user['data']['pockets']
  end

  def test_delete
    user = @server_connection.post("users", @attributes)['resource']
    @server_connection.delete(user['ref'])
    assert_raises(Fauna::Connection::NotFound) do
      @server_connection.get(user['ref'])
    end
  end
end
