require File.expand_path('../test_helper', __FILE__)

class ContextTest < FaunaTest
  def setup
    super

    Fauna::Context.reset
  end

  def teardown
    super

    Fauna::Context.reset
  end

  def test_push
    client = Fauna::Client.new

    Fauna::Context.push(client)
    assert_equal client, Fauna::Context.client
  end

  def test_pop
    client = Fauna::Client.new
    client2 = Fauna::Client.new

    Fauna::Context.push(client)
    Fauna::Context.push(client2)

    assert_equal client2, Fauna::Context.pop
    assert_equal client, Fauna::Context.client
  end

  def test_reset
    client = Fauna::Client.new

    Fauna::Context.push(client)
    assert_equal client, Fauna::Context.client

    Fauna::Context.reset
    assert_raises(Fauna::NoContextError) { Fauna::Context.client }
  end

  def test_block
    Fauna::Context.push(@root_client)

    assert_equal @root_client, Fauna::Context.client
    Fauna::Context.block(@server_client) do
      assert_equal @server_client, Fauna::Context.client
    end
    assert_equal @root_client, Fauna::Context.client
  end
end
