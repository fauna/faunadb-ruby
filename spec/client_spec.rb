RSpec.describe Fauna::Client do
  before(:all) do
    create_test_db
    @test_class = client.query { create_class(name: 'client_test') }[:ref]
  end

  after(:all) do
    destroy_test_db
  end

  describe 'connection' do
    # Compress string with gzip
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

    it 'decodes gzip response' do
      response = gzipped '{"resource": 1}'
      test_client = stub_client(:post, '/', response, 'Content-Encoding' => 'gzip')
      expect(test_client.query('tests/decode')).to be(1)
    end

    it 'decodes deflate response' do
      response = Zlib::Deflate.deflate '{"resource": 1}'
      test_client = stub_client(:post, '/', response, 'Content-Encoding' => 'deflate')
      expect(test_client.query('tests/decode')).to be(1)
    end
  end

  describe 'serialization' do
    it 'decodes ref' do
      ref = Fauna::Ref.new(random_number, Fauna::Ref.new(random_string, Fauna::Native.classes))
      test_client = stub_client(:post, '/', to_json(resource: ref))

      response = test_client.query('tests/ref')
      expect(response).to be_a(Fauna::Ref)
      expect(response).to eq(ref)
    end

    it 'decodes set' do
      set = Fauna::SetRef.new(match: Fauna::Ref.new(random_string, Fauna::Native.indexes), terms: random_string)
      test_client = stub_client(:post, '/', to_json(resource: set))

      response = test_client.query('tests/set')
      expect(response).to be_a(Fauna::SetRef)
      expect(response).to eq(set)
    end

    it 'decodes obj' do
      data = { random_string.to_sym => random_string }
      obj = { :@obj => data }
      test_client = stub_client(:post, '/', to_json(resource: obj))

      response = test_client.query('tests/obj')
      expect(response).to be_a(Hash)
      expect(response).to eq(data)
    end

    it 'decodes ts' do
      ts = Time.at(0).utc
      test_client = stub_client(:post, '/', to_json(resource: ts))

      response = test_client.query('tests/ts')
      expect(response).to be_a(Time)
      expect(response).to eq(ts)
    end

    it 'decodes date' do
      date = Date.new(1970, 1, 1)
      test_client = stub_client(:post, '/', to_json(resource: date))

      response = test_client.query('tests/date')
      expect(response).to be_a(Date)
      expect(response).to eq(date)
    end
  end

  describe '#with_secret' do
    it 'creates client with secret' do
      old_secret = random_string
      new_secret = random_string

      old_client = get_client(secret: old_secret)
      new_client = old_client.with_secret(new_secret)

      expect(old_client.credentials).to eq([old_secret])
      expect(new_client.credentials).to eq([new_secret])
    end
  end

  describe '#query' do
    it 'performs query from expression' do
      value = random_number

      instance = client.query { create(@test_class, data: { a: value }) }

      expect(instance[:ref].to_class).to eq(@test_class)
      expect(instance[:data][:a]).to eq(value)
    end

    it 'performs query from block' do
      value = random_number

      instance = client.query { create @test_class, data: { a: value } }

      expect(instance[:ref].to_class).to eq(@test_class)
      expect(instance[:data][:a]).to eq(value)
    end
  end

  describe '#ping' do
    it 'performs ping' do
      expect(client.ping).to eq('Scope global is OK')
    end

    it 'performs ping with scope' do
      expect(client.ping(scope: 'node')).to eq('Scope node is OK')
    end
  end
end
