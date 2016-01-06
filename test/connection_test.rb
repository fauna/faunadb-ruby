require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < FaunaTest
  def test_get
    response = echo(:get, 'tests/method').get('tests/method')
    assert_equal 'GET', response.body[:method]

    response = echo(:get, 'tests/method?test=param').get('tests/method', test: 'param')
    assert_equal 'GET', response.body[:method]
  end

  def test_post
    body = { test: RandomHelper.random_string }

    response = echo(:post, 'tests/method').post('tests/method', body)
    assert_equal 'POST', response.body[:method]
    assert_equal body, response.body[:body]
  end

  def test_put
    body = { test: RandomHelper.random_string }

    response = echo(:put, 'tests/method').put('tests/method', body)
    assert_equal 'PUT', response.body[:method]
    assert_equal body, response.body[:body]
  end

  def test_patch
    body = { test: RandomHelper.random_string }

    response = echo(:patch, 'tests/method').patch('tests/method', body)
    assert_equal 'PATCH', response.body[:method]
    assert_equal body, response.body[:body]
  end

  def test_delete
    body = { test: RandomHelper.random_string }

    response = echo(:delete, 'tests/method').delete('tests/method', body)
    assert_equal 'DELETE', response.body[:method]
    assert_equal body, response.body[:body]
  end

private

  def echo(method, url)
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.send(method, url) do |env|
      [200, {}, { method: env.method.to_s.upcase, body: JSON.load(env.body) }.to_json]
    end
    Connection.new nil, adapter: [:test, stubs]
  end
end
