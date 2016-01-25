require File.expand_path('../test_helper', __FILE__)

class ContextTest < FaunaTest
  def setup
    super

    Context.reset
  end

  def test_methods
    [:get, :post, :put, :patch, :delete].each do |method|
      client = stub_client method, '', [200, {}, '{ "resource": 1 }']
      Context.block(client) do
        assert_equal 1, Context.send(method, '')
      end
    end
  end

  def test_query
    Context.block(@server_client) do
      assert_equal [2, 3], (Context.query do
        map [1, 2] { |x| add x, 1 }
      end)
    end
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
