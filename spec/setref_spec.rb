RSpec.describe Fauna::SetRef do
  describe '#==' do
    it 'equals same set' do
      data = { match: random_ref, terms: random_string }
      set = Fauna::SetRef.new(data)

      expect(set).to eq(Fauna::SetRef.new(data))
    end

    it 'does not equal different set' do
      set = Fauna::SetRef.new(match: random_ref, terms: random_string)

      expect(set).not_to eq(Fauna::SetRef.new(match: random_ref, terms: random_string))
    end

    it 'does not equal other type' do
      data = { match: random_ref, terms: random_string }
      set = Fauna::SetRef.new(data)

      expect(set).not_to eq(data)
    end
  end
end
