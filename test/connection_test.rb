require File.expand_path('../test_helper', __FILE__)

class ConnectionTest < MiniTest::Unit::TestCase
  def setup
    super
    method_response = proc do |env|
      [200, @test_headers, { 'method' => env.method.to_s.upcase, 'body' => JSON.load(env.body) }.to_json]
    end

    @stubs.get('tests/method', &method_response)
    @stubs.get('tests/method?test=param', &method_response)
    @stubs.post('tests/method', &method_response)
    @stubs.put('tests/method', &method_response)
    @stubs.patch('tests/method', &method_response)
    @stubs.delete('tests/method', &method_response)
  end

  def test_get
    response = @test_connection.get('tests/method')
    assert_equal 'GET', response.body['method']

    response = @test_connection.get('tests/method', test: 'param')
    assert_equal 'GET', response.body['method']
  end

  def test_post
    body = { 'test' => RandomHelper.random_string }

    response = @test_connection.post('tests/method', body)
    assert_equal 'POST', response.body['method']
    assert_equal body, response.body['body']
  end

  def test_put
    body = { 'test' => RandomHelper.random_string }

    response = @test_connection.put('tests/method', body)
    assert_equal 'PUT', response.body['method']
    assert_equal body, response.body['body']
  end

  def test_patch
    body = { 'test' => RandomHelper.random_string }

    response = @test_connection.patch('tests/method', body)
    assert_equal 'PATCH', response.body['method']
    assert_equal body, response.body['body']
  end

  def test_delete
    body = { 'test' => RandomHelper.random_string }

    response = @test_connection.delete('tests/method', body)
    assert_equal 'DELETE', response.body['method']
    assert_equal body, response.body['body']
  end
end
