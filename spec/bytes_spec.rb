RSpec.describe Fauna::Bytes do
  describe '#initalize' do
    it 'creates from bytes' do
      raw = random_bytes
      expect(Fauna::Bytes.new(raw).bytes).to eq(raw)
    end
  end

  describe '#from_base64' do
    it 'creates from base64' do
      raw = random_bytes
      encoded = Base64.urlsafe_encode64(raw)

      expect(Fauna::Bytes.from_base64(encoded).bytes).to eq(raw)
    end
  end

  describe '#==' do
    it 'equals same bytes' do
      raw = random_bytes
      bytes = Fauna::Bytes.new(raw)

      expect(bytes).to eq(Fauna::Bytes.new(raw))
    end

    it 'does not equal different bytes' do
      expect(Fauna::Bytes.new(random_bytes)).not_to eq(Fauna::Bytes.new(random_bytes))
    end

    it 'does not equal other type' do
      raw = random_bytes

      expect(Fauna::Bytes.new(raw)).not_to eq(raw)
    end
  end
end
