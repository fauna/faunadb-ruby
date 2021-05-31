RSpec.describe Fauna::Context do
  before(:all) do
    create_test_db
    @test_class = client.query { create_collection(name: 'context_test') }[:ref]
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
        expect(Fauna::Context.paginate(Fauna::Query.expr { ref('collections') }).data).to eq([@test_class])
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
