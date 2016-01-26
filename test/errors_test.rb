require File.expand_path('../test_helper', __FILE__)

class ErrorsTest < FaunaTest
  def test_request_result
    err = assert_raises(BadRequest) do
      client.post '', foo: 'bar'
    end
    assert_equal({ foo: 'bar' }, err.request_result.request_content)
  end

  def test_bad_request
    assert_raises BadRequest do
      client.post '', foo: 'bar'
    end
  end

  def test_unauthorized
    client = get_client secret: 'bad_key'
    assert_http_error Unauthorized, 'unauthorized' do
      client.query Query.get(db_ref)
    end
  end

  def test_permission_denied
    # Create client with client key
    client = get_client secret: root_client.query(
      Query.create(
        Ref.new('keys'),
        Query.object(database: db_ref, role: :client)))[:secret]

    exception = assert_raises PermissionDenied do
      client.query(Query.paginate(Ref.new('databases')))
    end
    assert_error exception, 'permission denied', [:paginate]
  end

  def test_not_found
    assert_http_error NotFound, 'not found' do
      client.get 'classes/not_found'
    end
  end

  def test_method_not_allowed
    assert_http_error MethodNotAllowed, 'method not allowed' do
      client.delete 'classes'
    end
  end

  def test_internal_error
    code_client = stub_get 500,
      '{"errors": [{"code": "internal server error", "description": "sample text", "stacktrace": []}]}'
    assert_http_error InternalError, 'internal server error' do
      code_client.get ''
    end
  end

  def test_unavailable_error
    client = stub_get 503, '{"errors": [{"code": "unavailable", "description": "on vacation"}]}'
    assert_http_error UnavailableError, 'unavailable' do
      client.get ''
    end
  end

  def test_unknown_error
    client = stub_get 1337,
      '{"errors": [{"code": "who knows?", "description": "unexpected error code"}]}'
    assert_http_error FaunaError, 'who knows?' do
      client.get ''
    end
  end

  def test_query_error
    assert_query_error('invalid argument', [:add, 1], BadRequest) do
      add 1, :two
    end
  end

  def test_invalid_data
    assert_invalid_data 'classes', { name: 123 }, 'invalid type', [:name]
  end

  def test_inspect
    err = ErrorData.new 'code', 'desc', nil, nil
    assert_equal 'ErrorData("code", "desc", nil, nil)', err.inspect

    failure = Failure.new 'code', 'desc', [:a, :b]
    err = ErrorData.new 'code', 'desc', [:pos], [failure]
    assert_equal 'ErrorData("code", "desc", [:pos], [Failure("code", "desc", [:a, :b])])', err.inspect
  end

private

  def stub_get(status_code, response)
    stub_client :get, '', [status_code, {}, response]
  end

  def assert_http_error(exception_cls, code, &block)
    exception = assert_raises exception_cls, &block
    assert_error exception, code
  end

  def assert_error(exception, code, position = nil)
    assert_equal 1, exception.errors.length
    error = exception.errors[0]
    assert_equal code, error.code
    assert_equal position, error.position
  end

  def assert_query_error(code, position, error_class, &block)
    exception = assert_raises(error_class) do
      client.query &block
    end
    assert_error exception, code, position
  end

  def assert_invalid_data(class_name, data, code, field)
    exception = assert_raises BadRequest do
      client.post class_name, data
    end
    assert_error exception, 'validation failed', []
    failures = exception.errors[0].failures
    assert_equal 1, failures.length
    failure = failures[0]
    assert_equal code, failure.code
    assert_equal field, failure.field
  end
end
