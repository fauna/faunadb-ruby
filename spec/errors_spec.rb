RSpec.describe 'Fauna Errors' do
  RSpec::Matchers.define :raise_fauna_error do |exception, code, position = nil|
    match do |block|
      expect(&block).to raise_error(exception) do |ex|
        expect(ex.errors.length).to be(1)
        error = ex.errors.first
        expect(error.code).to eq(code)
        expect(error.position).to eq(position)
      end
    end

    def supports_block_expectations?
      true
    end
  end

  before(:all) do
    create_test_db
  end

  after(:all) do
    destroy_test_db
  end

  # Create client with stub adapter responding to / with the given status and response
  def stub_get(status_code, response)
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get '/' do
      [status_code, {}, response]
    end
    Fauna::Client.new(adapter: [:test, stubs])
  end

  # Create client with stub adapter responding to / with the given exception
  def stub_error(exception)
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get '/' do
      fail exception
    end
    Fauna::Client.new(adapter: [:test, stubs])
  end

  it 'sets request result' do
    expect { client.post '', foo: 'bar' }.to raise_error do |err|
      expect(err).to be_a(Fauna::BadRequest)
      expect(err.request_result.request_content).to eq(foo: 'bar')
    end
  end

  it 'parses query errors' do
    expect { client.query { add 1, :two } }.to raise_fauna_error(Fauna::BadRequest, 'invalid argument', [:add, 1])
  end

  it 'parses invalid data' do
    expect { client.query { create ref('classes'), name: 123 } }.to raise_error(Fauna::BadRequest) do |err|
      expect(err.errors.length).to eq(1)
      error = err.errors.first

      expect(error.code).to eq('validation failed')
      expect(error.position).to eq([])
      expect(error.failures.length).to eq(1)
      failure = error.failures.first

      expect(failure.code).to eq('invalid type')
      expect(failure.field).to eq([:name])
    end
  end

  describe Fauna::ErrorData do
    it 'handles inspect' do
      err = Fauna::ErrorData.new 'code', 'desc', nil, nil
      expect(err.inspect).to eq('ErrorData("code", "desc", nil, nil)')
    end

    it 'handles inspect with failures' do
      failure = Fauna::Failure.new 'code', 'desc', [:a, :b]
      err = Fauna::ErrorData.new 'code', 'desc', [:pos], [failure]
      expect(err.inspect).to eq('ErrorData("code", "desc", [:pos], [Failure("code", "desc", [:a, :b])])')
    end
  end

  describe Fauna::BadRequest do
    it 'is handled' do
      expect { client.post '', foo: 'bar' }.to raise_error(Fauna::BadRequest)
    end
  end

  describe Fauna::Unauthorized do
    it 'is handled' do
      bad_client = get_client secret: 'bad_key'
      expect { bad_client.query { get @db_ref } }.to raise_error(Fauna::Unauthorized)
    end
  end

  describe Fauna::PermissionDenied do
    it 'is handled' do
      key = root_client.query { create ref('keys'), database: @db_ref, role: :client }

      expect { get_client(secret: key[:secret]).query { paginate ref('databases') } }.to raise_fauna_error(
        Fauna::PermissionDenied, 'permission denied', [:paginate])
    end
  end

  describe Fauna::NotFound do
    it 'is handled' do
      expect { client.get 'classes/no_class' }.to raise_fauna_error(Fauna::NotFound, 'not found')
    end
  end

  describe Fauna::MethodNotAllowed do
    it 'is handled' do
      expect { client.delete 'classes' }.to raise_fauna_error(Fauna::MethodNotAllowed, 'method not allowed')
    end
  end

  describe Fauna::InternalError do
    it 'is handled' do
      stub_client = stub_get 500,
        '{"errors": [{"code": "internal server error", "description": "sample text", "stacktrace": []}]}'

      expect { stub_client.get '' }.to raise_fauna_error(Fauna::InternalError, 'internal server error')
    end
  end

  describe Fauna::UnavailableError do
    it 'handles fauna 503' do
      stub_client = stub_get 503, '{"errors": [{"code": "unavailable", "description": "on vacation"}]}'
      expect { stub_client.get '' }.to raise_fauna_error(Fauna::UnavailableError, 'unavailable')
    end

    it 'handles upstream 503' do
      stub_client = stub_get 503, 'Unable to reach server'
      expect { stub_client.get '' }.to raise_error(Fauna::UnavailableError, 'Unable to reach server')
    end

    it 'handles timeout error' do
      stub_client = stub_error Faraday::TimeoutError.new('timeout')
      expect { stub_client.get '' }.to raise_error(Fauna::UnavailableError, 'Faraday::TimeoutError: timeout')
    end

    it 'handles connection error' do
      stub_client = stub_error Faraday::ConnectionFailed.new('connection refused')
      expect { stub_client.get '' }.to raise_error(Fauna::UnavailableError, 'Faraday::ConnectionFailed: connection refused')
    end
  end

  describe Fauna::UnexpectedError do
    it 'raised for json error' do
      expect { stub_get(200, 'I like fine wine').get('') }.to raise_error(Fauna::UnexpectedError, /json/i) do |err|
        rr = err.request_result
        expect(rr.response_content).to be_nil
        expect(rr.response_raw).to eq('I like fine wine')
      end
    end

    it 'raised for missing resource' do
      expect { stub_get(200, '{"notaresource": 1}').get('') }.to raise_error(Fauna::UnexpectedError, /expected key/)
    end

    it 'raised for unexpected code' do
      expect { stub_get(1337, '{"errors": []}').get('') }.to raise_error(Fauna::UnexpectedError, /status code/)
    end

    it 'raised for bad errors format' do
      expect { stub_get(500, '{"errors": true}').get('') }.to raise_error(Fauna::UnexpectedError, /unexpected format/)
    end

    it 'raised for empty errors' do
      expect { stub_get(500, '{"errors": []}').get('') }.to raise_error(Fauna::UnexpectedError, /blank/)
    end
  end
end
