require File.expand_path('../test_helper', __FILE__)

class ErrorsTest < FaunaTest
  def test_request_result
    err = assert_raises(BadRequest) do
      client.query foo: 'bar'
    end
    assert_equal({ foo: 'bar' }, err.request_result.request_content)
  end
end
