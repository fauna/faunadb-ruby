RSpec.describe Fauna::Ref do
  it 'converts to string' do
    db = Fauna::Ref.new('db', Fauna::Native.databases)
    expect(db.to_s).to eq('Ref(id=db,class=Ref(id=databases))')

    cls = Fauna::Ref.new('cls', Fauna::Native.classes, db)
    expect(cls.to_s).to eq('Ref(id=cls,class=Ref(id=classes),database=Ref(id=db,class=Ref(id=databases)))')

    expect(Fauna::Ref.new('test', cls).to_s).to eq('Ref(id=test,class=Ref(id=cls,class=Ref(id=classes),database=Ref(id=db,class=Ref(id=databases))))')
  end

  describe '#id' do
    it 'returns id portion' do
      expect(Fauna::Ref.new('test', Fauna::Native.classes).id).to eq('test')
    end

    it 'raises error' do
      expect { Fauna::Ref.new(nil) }.to raise_error(ArgumentError)
    end
  end

  describe '#to_class' do
    context 'with id and user class' do
      it 'returns class portion' do
        expect(Fauna::Ref.new('1234', Fauna::Ref.new('test', Fauna::Native.classes)).to_class).to eq(Fauna::Ref.new('test', Fauna::Native.classes))
      end
    end

    context 'user class only' do
      it 'returns class portion' do
        expect(Fauna::Ref.new('test', Fauna::Native.classes).to_class).to eq(Fauna::Native.classes)
      end
    end

    context 'without id and user class' do
      it 'returns class portion' do
        expect(Fauna::Ref.new('classes').to_class).to be_nil
      end
    end

    context 'with native classes' do
      it 'returns class portion' do
        expect(Fauna::Native.classes.to_class).to be_nil
        expect(Fauna::Native.indexes.to_class).to be_nil
        expect(Fauna::Native.databases.to_class).to be_nil
        expect(Fauna::Native.functions.to_class).to be_nil
        expect(Fauna::Native.keys.to_class).to be_nil
      end
    end
  end

  describe '#to_database' do
    db = Fauna::Ref.new('db', Fauna::Native.databases)

    context 'with simple database' do
      it 'returns database portion' do
        expect(Fauna::Ref.new('test', Fauna::Native.classes, db).to_database).to eq(Fauna::Ref.new('db', Fauna::Native.databases))
      end
    end

    context 'with nested database' do
      it 'returns database portion' do
        nested_db = Fauna::Ref.new('nested-db', Fauna::Native.databases, db)
        deep_db = Fauna::Ref.new('deep-db', Fauna::Native.databases, nested_db)

        expect(nested_db.to_database).to eq(db)
        expect(deep_db.to_database.to_database).to eq(db)
      end
    end

    context 'with native classes' do
      it 'returns database portion' do
        expect(Fauna::Native.classes.to_database).to be_nil
        expect(Fauna::Native.indexes.to_database).to be_nil
        expect(Fauna::Native.databases.to_database).to be_nil
        expect(Fauna::Native.functions.to_database).to be_nil
        expect(Fauna::Native.keys.to_database).to be_nil
      end
    end
  end

  describe '#==' do
    it 'equals same ref' do
      ref = Fauna::Ref.new('123', Fauna::Ref.new('test', Fauna::Native.classes))

      expect(ref).to eq(Fauna::Ref.new('123', Fauna::Ref.new('test', Fauna::Native.classes)))
    end

    it 'does not equal different ref' do
      ref = Fauna::Ref.new('123', Fauna::Ref.new('test', Fauna::Native.classes))

      expect(ref).not_to eq(Fauna::Ref.new('321', Fauna::Ref.new('test', Fauna::Native.classes)))
    end

    it 'does not equal other type' do
      expect(Fauna::Ref.new('test', Fauna::Native.classes)).not_to eq('classes/test')
    end
  end
end
