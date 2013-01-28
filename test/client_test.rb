require File.expand_path('../test_helper', __FILE__)

class ClientTest < MiniTest::Unit::TestCase
  def setup
    super
    @attributes = { "name" => "Princess Eilonwy", "email" => email, "password" => password }
  end

  def test_publisher_context
    Fauna::Client.context(@publisher_connection) do
      user = Fauna::Client.post("users", @attributes)
      user = Fauna::Client.get(user.ref)
      Fauna::Client.delete(user.ref)
    end
  end

  def test_client_context
    Fauna::Client.context(@client_connection) do
      user = Fauna::Client.post("users", @attributes)
      Fauna::Client.context(@client_connection) do
        assert_raises(Fauna::Connection::Unauthorized) do
          Fauna::Client.get(user.ref)
        end
      end
    end
  end

  def test_token_context
    Fauna::Client.context(@publisher_connection) do
      Fauna::Client.post("users", @attributes)
    end

    Fauna::Client.context(@client_connection) do
      @token = Fauna::Client.post("tokens", @attributes)
    end

    Fauna::Client.context(Fauna::Connection.new(:token => @token.token)) do
      user = Fauna::Client.get(@token.user)
      Fauna::Client.delete(user.ref)
    end
  end

  def test_caching_1
    Fauna::Client.context(@publisher_connection) do
      @user = Fauna::Client.post("users", @attributes)
      @publisher_connection.expects(:get).never
      Fauna::Client.get(@user.ref)
    end
  end

  def test_caching_2
    Fauna::Client.context(@client_connection) do
      @user = Fauna::Client.post("users", @attributes)

      Fauna::Client.context(@publisher_connection) do
        Fauna::Client.get(@user.ref)
        @publisher_connection.expects(:get).never
        Fauna::Client.get(@user.ref)
      end
    end
  end
end
