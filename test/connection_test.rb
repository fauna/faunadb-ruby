require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < FaunaTest
  def test_get
    response = echo(:get, 'tests/method').get('tests/method')
    assert_equal 'GET', response[:method]

    response = echo(:get, 'tests/method?test=param').get('tests/method', test: 'param')
    assert_equal 'GET', response[:method]
  end

  def test_post
    body = { test: RandomHelper.random_string }

    response = echo(:post, 'tests/method').post('tests/method', body)
    assert_equal 'POST', response[:method]
    assert_equal body, response[:body]
  end

  def test_put
    body = { test: RandomHelper.random_string }

    response = echo(:put, 'tests/method').put('tests/method', body)
    assert_equal 'PUT', response[:method]
    assert_equal body, response[:body]
  end

  def test_patch
    body = { test: RandomHelper.random_string }

    response = echo(:patch, 'tests/method').patch('tests/method', body)
    assert_equal 'PATCH', response[:method]
    assert_equal body, response[:body]
  end

  def test_delete
    response = echo(:delete, 'tests/method').delete('tests/method')
    assert_equal 'DELETE', response[:method]
  end

  def test_gzip
    gz = gzipped '{"resource": 1}'
    test_client = stub_client(:get, '',
      [200, { 'Content-Encoding' => 'gzip' }, gz])
    assert_equal 1, test_client.get('')
  end

  def test_deflate
    df = Zlib::Deflate.deflate '{"resource": 1}'
    test_client = stub_client(:get, '',
      [200, { 'Content-Encoding' => 'deflate' }, df])
    assert_equal 1, test_client.get('')
  end

private

  def echo(method, url)
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.send(method, url) do |env|
      [200, {}, { resource: { method: env.method.to_s.upcase, body: JSON.load(env.body) } }.to_json]
    end
    Connection.new nil, adapter: [:test, stubs]
  end

  def gzipped(str)
    out = ''
    StringIO.open out do |io|
      writer = Zlib::GzipWriter.new io
      writer.write str
      writer.flush
      writer.close
    end
    out
  end
end
