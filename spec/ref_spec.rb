RSpec.describe Fauna::Ref do
  it 'converts to string' do
    expect(Fauna::Ref.new('classes/test').to_s).to eq('classes/test')
  end

  describe '#initalize' do
    it 'creates from string' do
      name = random_string
      expect(Fauna::Ref.new("classes/#{name}").value).to eq("classes/#{name}")
    end
  end

  describe '#id' do
    context 'with multiple elements' do
      it 'returns id portion' do
        expect(Fauna::Ref.new('classes/test').id).to eq('test')
      end
    end

    context 'with single element' do
      it 'raises error' do
        expect { Fauna::Ref.new('classes').id }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_class' do
    context 'with multiple elements' do
      it 'returns class portion' do
        expect(Fauna::Ref.new('classes/test').to_class).to eq(Fauna::Ref.new('classes'))
      end
    end

    context 'with single element' do
      it 'returns class portion' do
        expect(Fauna::Ref.new('classes').to_class).to eq(Fauna::Ref.new('classes'))
      end
    end
  end

  describe '#==' do
    it 'equals same ref' do
      ref = Fauna::Ref.new('classes/test')

      expect(ref).to eq(Fauna::Ref.new('classes/test'))
      expect(ref.to_class).to eq(Fauna::Ref.new('classes'))
    end

    it 'does not equal different ref' do
      expect(Fauna::Ref.new('classes/test')).not_to eq(Fauna::Ref.new('classes'))
    end

    it 'does not equal other type' do
      expect(Fauna::Ref.new('classes/test')).not_to eq('classes/test')
    end
  end
end
