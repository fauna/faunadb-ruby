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
    assert_http_error Unauthorized, :unauthorized do
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
    assert_error exception, :'permission denied', [:paginate]
  end

  def test_not_found
    assert_http_error NotFound, :'not found' do
      client.get 'classes/not_found'
    end
  end

  def test_method_not_allowed
    assert_http_error MethodNotAllowed, :'method not allowed' do
      client.delete 'classes'
    end
  end
  def test_internal_error
    code_client = stub_get 500,
      '{"errors": [{"code": "internal server error", "description": "sample text", "stacktrace": []}]}'
    assert_http_error InternalError, :'internal server error' do
      code_client.get ''
    end
  end

  def test_unavailable_error
    client = stub_get 503, '{"errors": [{"code": "unavailable", "description": "on vacation"}]}'
    assert_http_error UnavailableError, :unavailable do
      client.get ''
    end
  end

  def test_invalid_expression
    assert_query_error :'invalid expression' do
      Query::Expr.new foo: 'bar'
    end
  end

  def test_unbound_variable
    assert_query_error :'unbound variable' do
      var :x
    end
  end

  def test_invalid_argument
    assert_query_error(:'invalid argument', [:add, 1]) do
      add 1, :two
    end
  end

  def test_instance_not_found
    # Must be a reference to a real class or else we get InvalidExpression
    client.post 'classes', name: 'foofaws'
    assert_query_error :'instance not found', [], NotFound do
      get Ref.new('classes/foofaws/123')
    end
  end

  def test_value_not_found
    assert_query_error :'value not found', [], NotFound do
      select :a, {}
    end
  end

  def test_instance_already_exists
    client.post 'classes', name: 'duplicates'
    ref = client.post('classes/duplicates', {})[:ref]
    assert_query_error :'instance already exists', [:create] do
      create ref, {}
    end
  end

  def test_invalid_type
    assert_invalid_data 'classes', { name: 123 }, :'invalid type', [:name]
  end

  def test_value_required
    assert_invalid_data 'classes', {}, :'value required', [:name]
  end

  def test_duplicate_value
    client.post 'classes', name: 'gerbils'
    client.post 'indexes',
      name: 'gerbils_by_x',
      source: { :@ref => 'classes/gerbils' },
      terms: [{ path: 'data.x' }],
      unique: true,
      active: true
    client.post 'classes/gerbils', data: { x: 1 }
    assert_invalid_data 'classes/gerbils', { data: { x: 1 } }, :'duplicate value', [:data, :x]
  end

  def test_inspect
    err = ErrorData.new :code, 'desc', nil
    assert_equal 'ErrorData(:code, "desc", nil)', err.inspect

    failure = Failure.new :code, 'desc', [:a, :b]
    vf = ValidationFailed.new :vf_desc, [:vf], [failure]
    assert_equal 'ValidationFailed(:vf_desc, [:vf], [Failure(:code, "desc", [:a, :b])])', vf.inspect
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

  def assert_query_error(code, position = [], errorClass = BadRequest, &block)
    exception = assert_raises(errorClass) do
      client.query &block
    end
    assert_error exception, code, position
  end

  def assert_invalid_data(class_name, data, code, field)
    exception = assert_raises BadRequest do
      client.post class_name, data
    end
    assert_error exception, :'validation failed', []
    failures = exception.errors[0].failures
    assert_equal 1, failures.length
    failure = failures[0]
    assert_equal code, failure.code
    assert_equal field, failure.field
  end
end
