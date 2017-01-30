RSpec.describe Fauna::Bytes do
  describe '#initalize' do
    it 'creates from bytes' do
      bytes = "\x01\x02\x03"
      expect(Fauna::Bytes.new(bytes).bytes).to eq(bytes)
    end
  end

  describe '#from_base64' do
    it 'creates from base64' do
      encoded = 'AQID'
      expect(Fauna::Bytes.from_base64(encoded).bytes).to eq("\x01\x02\x03")
    end

    it 'does not require padding' do
      pad = 'AQIDBA=='
      no_pad = 'AQIDBA'

      expect { Fauna::Bytes.from_base64(no_pad) }.not_to raise_error
      expect(Fauna::Bytes.from_base64(no_pad)).to eq(Fauna::Bytes.from_base64(pad))
    end
  end

  describe '#==' do
    it 'equals same bytes' do
      bytes = Fauna::Bytes.new("\x01\x02\x03")

      expect(bytes).to eq(Fauna::Bytes.new("\x01\x02\x03"))
    end

    it 'does not equal different bytes' do
      expect(Fauna::Bytes.new("\x04\x05\x06")).not_to eq(Fauna::Bytes.new("\x01\x02\x03"))
    end

    it 'does not equal other type' do
      expect(Fauna::Bytes.new("\x01\x02\x03")).not_to eq("\x01\x02\x03")
    end
  end
end
