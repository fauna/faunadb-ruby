RSpec.describe Fauna::Context do
  before(:all) do
    create_test_db
    @test_class = client.post('classes', name: 'context_test')[:ref]
  end

  after(:all) do
    destroy_test_db
  end

  around do |ex|
    # Ensure context is not shared between tests
    Fauna::Context.reset
    ex.run
    Fauna::Context.reset
  end

  describe 'REST methods' do
    around do |ex|
      stubs = Faraday::Adapter::Test::Stubs.new
      [:get, :post, :put, :patch, :delete].each do |method|
        stubs.send(method, '/tests/context') do |env|
          [200, {}, { resource: env.method.to_s.upcase }.to_json]
        end
      end

      Fauna::Context.block(Fauna::Client.new(adapter: [:test, stubs])) do
        ex.run
      end
    end

    describe '#get' do
      it 'performs GET request' do
        expect(Fauna::Context.get('tests/context')).to eq('GET')
      end
    end

    describe '#post' do
      it 'performs POST request' do
        expect(Fauna::Context.post('tests/context')).to eq('POST')
      end
    end

    describe '#put' do
      it 'performs PUT request' do
        expect(Fauna::Context.put('tests/context')).to eq('PUT')
      end
    end

    describe '#patch' do
      it 'performs PATCH request' do
        expect(Fauna::Context.patch('tests/context')).to eq('PATCH')
      end
    end

    describe '#delete' do
      it 'performs DELETE request' do
        expect(Fauna::Context.delete('tests/context')).to eq('DELETE')
      end
    end
  end

  describe '#query' do
    it 'performs query' do
      Fauna::Context.block(client) do
        expect(Fauna::Context.query { add 1, 1 }).to eq(2)
      end
    end
  end

  describe '#paginate' do
    it 'performs paginate' do
      Fauna::Context.block(client) do
        expect(Fauna::Context.paginate(Fauna::Query.expr { ref('classes') }).data).to eq([@test_class])
      end
    end
  end

  describe '#push' do
    it 'pushes new client' do
      new = Fauna::Client.new

      Fauna::Context.push(new)
      expect(Fauna::Context.client).to be(new)
    end
  end

  describe '#pop' do
    it 'pops active client' do
      outer = Fauna::Client.new
      inner = Fauna::Client.new

      Fauna::Context.push(outer)
      Fauna::Context.push(inner)

      expect(Fauna::Context.pop).to be(inner)
      expect(Fauna::Context.client).to be(outer)
    end
  end

  describe '#reset' do
    it 'resets stack' do
      initial = Fauna::Client.new
      outer = Fauna::Client.new
      inner = Fauna::Client.new

      Fauna::Context.push(initial)
      Fauna::Context.push(outer)
      Fauna::Context.push(inner)

      Fauna::Context.reset
      expect { Fauna::Context.client }.to raise_error(Fauna::NoContextError)
    end
  end

  describe '#block' do
    it 'changes client within block' do
      outer = Fauna::Client.new
      inner = Fauna::Client.new
      Fauna::Context.push(outer)

      expect(Fauna::Context.client).to be(outer)
      Fauna::Context.block(inner) do
        expect(Fauna::Context.client).to be(inner)
      end
      expect(Fauna::Context.client).to be(outer)
    end
  end
end
