RSpec.describe Fauna::ClientLogger do
  before(:all) do
    create_test_db
    @test_class = client.query { create_class(name: 'logger_test') }[:ref]
  end

  after(:all) do
    destroy_test_db
  end

  # Captures logger output from wrapped client and splits it into lines
  def capture_log
    lines = nil
    observer = Fauna::ClientLogger.logger { |log| lines = log.split("\n") }

    yield get_client(secret: @server_secret, observer: observer)

    lambda { lines.shift }
  end

  it 'logs response' do
    reader = capture_log do |client|
      expect(client.ping).to eq('Scope global is OK')
    end

    expect(reader.call).to eq('Fauna GET /ping')
    expect(reader.call).to match(/^  Credentials:/)
    expect(reader.call).to eq('  Response headers: {')

    # Skip through headers
    loop do
      line = reader.call
      unless line.start_with? '    '
        expect(line).to eq('  }')
        break
      end
    end

    expect(reader.call).to eq('  Response JSON: {')
    expect(reader.call).to eq('    "resource": "Scope global is OK"')
    expect(reader.call).to eq('  }')
    expect(reader.call).to match(/^  Response \(200\): Network latency \d+ms$/)
  end

  it 'logs request content' do
    value = random_number
    reader = capture_log do |client|
      client.query data: { a: value }
    end

    expect(reader.call).to eq("Fauna POST /")
    expect(reader.call).to match(/^  Credentials:/)
    expect(reader.call).to eq('  Request JSON: {')
    expect(reader.call).to eq('    "object": {')
    expect(reader.call).to eq('      "data": {')
    expect(reader.call).to eq('        "object": {')
    expect(reader.call).to eq("          \"a\": #{value}")
    expect(reader.call).to eq('        }')
    expect(reader.call).to eq('      }')
    expect(reader.call).to eq('    }')
    expect(reader.call).to eq('  }')
    # Ignore the rest
  end

  it 'logs request query' do
    reader = capture_log do |client|
      client.ping scope: 'global'
    end

    expect(reader.call).to eq("Fauna GET /ping?scope=global")
    # Ignore the rest
  end
end
