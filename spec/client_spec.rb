RSpec.describe Fauna::Client do
  before(:all) do
    create_test_db
    @test_class = client.post('classes', name: 'client_test')[:ref]
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
      test_client = stub_client(:get, 'tests/decode', response, 'Content-Encoding' => 'gzip')
      expect(test_client.get('tests/decode')).to be(1)
    end

    it 'decodes deflate response' do
      response = Zlib::Deflate.deflate '{"resource": 1}'
      test_client = stub_client(:get, 'tests/decode', response, 'Content-Encoding' => 'deflate')
      expect(test_client.get('tests/decode')).to be(1)
    end
  end

  describe 'serialization' do
    it 'decodes ref' do
      ref = Fauna::Ref.new('classes', random_string, random_number)
      test_client = stub_client(:get, 'tests/ref', to_json(resource: ref))

      response = test_client.get('tests/ref')
      expect(response).to be_a(Fauna::Ref)
      expect(response).to eq(ref)
    end

    it 'decodes set' do
      set = Fauna::SetRef.new(match: random_string, index: Fauna::Ref.new('indexes', random_string))
      test_client = stub_client(:get, 'tests/set', to_json(resource: set))

      response = test_client.get('tests/set')
      expect(response).to be_a(Fauna::SetRef)
      expect(response).to eq(set)
    end

    it 'decodes obj' do
      data = { random_string.to_sym => random_string }
      obj = { :@obj => data }
      test_client = stub_client(:get, 'tests/obj', to_json(resource: obj))

      response = test_client.get('tests/obj')
      expect(response).to be_a(Hash)
      expect(response).to eq(data)
    end

    it 'decodes ts' do
      ts = Time.at(0).utc
      test_client = stub_client(:get, 'tests/ts', to_json(resource: ts))

      response = test_client.get('tests/ts')
      expect(response).to be_a(Time)
      expect(response).to eq(ts)
    end

    it 'decodes date' do
      date = Date.new(1970, 1, 1)
      test_client = stub_client(:get, 'tests/date', to_json(resource: date))

      response = test_client.get('tests/date')
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

      instance = client.query(Fauna::Query.create(@test_class, data: { a: value }))

      expect(instance[:class]).to eq(@test_class)
      expect(instance[:data][:a]).to eq(value)
    end

    it 'performs query from block' do
      value = random_number

      instance = client.query { create @test_class, data: { a: value } }

      expect(instance[:class]).to eq(@test_class)
      expect(instance[:data][:a]).to eq(value)
    end
  end

  describe '#get' do
    it 'performs GET' do
      value = random_number
      ref = client.post(@test_class, data: { a: value })[:ref]

      instance = client.get(ref)

      expect(instance[:ref]).to eq(ref)
      expect(instance[:data][:a]).to eq(value)
    end

    it 'performs GET with query' do
      value = random_number
      created = client.post(@test_class, data: { a: value })
      ref = created[:ref]
      ts = created[:ts]

      instance = client.get(ref, ts: ts)

      expect(instance[:ref]).to eq(ref)
      expect(instance[:data][:a]).to eq(value)

      expect { client.get(ref, ts: ts - 1) }.to raise_error(Fauna::NotFound)
    end
  end

  describe '#post' do
    it 'performs POST' do
      value = random_number

      instance = client.post(@test_class, data: { a: value })

      expect(instance[:class]).to eq(@test_class)
      expect(instance[:data][:a]).to eq(value)
    end
  end

  describe '#put' do
    it 'performs PUT' do
      value = random_number
      ref = client.post(@test_class, data: { a: random_number })[:ref]

      instance = client.put(ref, data: { b: value })

      expect(instance[:ref]).to eq(ref)
      expect(instance[:data][:a]).to be_nil
      expect(instance[:data][:b]).to eq(value)
    end
  end

  describe '#patch' do
    it 'performs PATCH' do
      value1 = random_number
      value2 = random_number
      ref = client.post(@test_class, data: { a: value1 })[:ref]

      instance = client.patch(ref, data: { b: value2 })

      expect(instance[:ref]).to eq(ref)
      expect(instance[:data][:a]).to eq(value1)
      expect(instance[:data][:b]).to eq(value2)
    end
  end

  describe '#delete' do
    it 'performs DELETE' do
      ref = client.post(@test_class, data: { a: random_number })[:ref]

      instance = client.delete(ref)

      expect(instance[:ref]).to eq(ref)
      expect { client.get(ref) }.to raise_error(Fauna::NotFound)
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
