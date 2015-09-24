require File.expand_path('../test_helper', __FILE__)

class ClientTest < FaunaTest # rubocop:disable Metrics/ClassLength
  def test_decode_ref
    test_ref = Fauna::Ref.new('classes', RandomHelper.random_string, RandomHelper.random_number)

    test_client = stub_client :get, 'tests/ref', [200, {}, { resource: test_ref.to_hash }.to_json]
    response = test_client.get('tests/ref')
    assert response.is_a?(Fauna::Ref)
    assert_equal test_ref, response
  end

  def test_decode_set
    test_set_match = RandomHelper.random_string
    test_set_index = Fauna::Ref.new("indexes/#{RandomHelper.random_string}")

    set = Fauna::Set.new(match: test_set_match, index: test_set_index)
    test_client = stub_client :get, 'tests/set', [200, {}, { resource: set }.to_json]

    response = test_client.get('tests/set')
    assert response.is_a?(Fauna::Set)
    assert_equal test_set_match, response.value[:match]
    assert_equal test_set_index.value, response.value[:index].value
  end

  def test_decode_obj
    test_obj_key = RandomHelper.random_string.to_sym
    test_obj_value = RandomHelper.random_string

    test_client = stub_client(:get, 'tests/obj',
      [200, {}, { resource: { :@obj => { test_obj_key => test_obj_value } } }.to_json])

    response = test_client.get('tests/obj')
    assert response.is_a?(Hash)
    assert_equal test_obj_value, response[test_obj_key]
  end

  def test_invalid_key
    client = get_client(secret: 'xyz')
    assert_raises Fauna::Unauthorized do
      client.get(db_ref)
    end
  end

  def test_ping
    assert_equal 'Scope Global is OK', client.ping
    assert_equal 'Scope Global is OK', client.ping(scope: 'global')
    assert_equal 'Scope Local is OK', client.ping(scope: 'local')
    assert_equal 'Scope Node is OK', client.ping(scope: 'node')
    assert_equal 'Scope All is OK', client.ping(scope: 'all')
  end

  def test_get
    assert client.get('classes')[:data].is_a?(Array)
  end

  def test_post
    cls = create_class
    assert client.get(cls[:ref]) == cls
  end

  def test_put
    create_class
    instance = create_instance
    instance = client.put instance[:ref], data: { a: 2 }

    assert_equal 2, instance[:data][:a]

    instance = client.put instance[:ref], data: { b: 3 }
    assert !instance[:data].include?(:a)
    assert_equal 3, instance[:data][:b]
  end

  def test_patch
    create_class
    instance = create_instance
    instance = client.patch instance[:ref], data: { a: 1 }
    instance = client.patch instance[:ref], data: { b: 2 }
    assert_equal({ a: 1, b: 2 }, instance[:data])
  end

  def test_delete
    cls_ref = create_class[:ref]
    client.delete cls_ref
    assert_raises(Fauna::NotFound) do
      client.get cls_ref
    end
  end

  def test_logging
    _, err = capture_io do
      test_client = stub_client(:get, 'ping',
        [200, { 'X-HTTP-Request-Processing-Time' => '123' }, '{ "resource": "Scope Global is OK" }'],
        logger: Logger.new($stderr),
        secret: 'abc:def')
      test_client.ping
    end

    lines = err.split("\n").map do |message|
      # Take off beginning part (timestamp)
      message.partition('-- : ')[2]
    end

    assert_equal '''Fauna GET /ping
  Credentials: ["abc", "def"]
  Response headers: {
    "X-HTTP-Request-Processing-Time": "123"
  }
  Response JSON: {
    "resource": "Scope Global is OK"
  }''', lines[0...-1].join("\n")
    assert(/^  Response \(200\): API processing 123ms, network latency \dms$/ =~ lines.last)
  end

private

  def stub_client(method, url, response, params = {})
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.send(method, url) do
      response
    end
    Fauna::Client.new({ adapter: [:test, stubs] }.merge params)
  end

  def create_class
    client.post 'classes', name: 'my_class'
  end

  def create_instance
    client.post 'classes/my_class', {}
  end
end
