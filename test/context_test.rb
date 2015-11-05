require File.expand_path('../test_helper', __FILE__)

class ContextTest < FaunaTest
  def setup
    super

    Context.reset
  end

  def teardown
    super

    Context.reset
  end

  def test_push
    client = Client.new

    Context.push(client)
    assert_equal client, Context.client
  end

  def test_pop
    client = Client.new
    client2 = Client.new

    Context.push(client)
    Context.push(client2)

    assert_equal client2, Context.pop
    assert_equal client, Context.client
  end

  def test_reset
    client = Client.new

    Context.push(client)
    assert_equal client, Context.client

    Context.reset
    assert_raises(NoContextError) { Context.client }
  end

  def test_block
    Context.push(@root_client)

    assert_equal @root_client, Context.client
    Context.block(@server_client) do
      assert_equal @server_client, Context.client
    end
    assert_equal @root_client, Context.client
  end
end
