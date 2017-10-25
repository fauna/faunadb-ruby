RSpec.describe Fauna::FaunaJson do
  describe '#deserialize' do
    it 'deserializes ref' do
      ref = random_ref_string

      data = { :@ref => { id: ref } }
      obj = Fauna::Ref.new(ref)

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end

    it 'deserializes set' do
      ref = random_ref_string
      terms = random_string

      data = { :@set => { match: { :@ref => { id: ref } }, terms: terms } }
      obj = Fauna::SetRef.new(match: Fauna::Ref.new(ref), terms: terms)

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end

    it 'deserializes query' do
      query = { lambda: 'a', expr: { add: [{ var: 'a' }, 1] } }
      obj = Fauna::QueryV.new(query)

      expect(Fauna::FaunaJson.deserialize(:@query => query)).to eq(obj)
    end

    it 'deserializes obj' do
      obj = { a: random_string, b: random_string }
      data = { :@obj => obj }

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end

    it 'deserializes ts' do
      data = { :@ts => '1970-01-01T00:00:00.000000000Z' }
      obj = Time.at(0).utc

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end

    it 'deserializes date' do
      data = { :@date => '1970-01-01' }
      obj = Date.new(1970, 1, 1)

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end

    it 'deserializes bytes' do
      raw = random_bytes

      data = { :@bytes => Base64.urlsafe_encode64(raw) }
      obj = Fauna::Bytes.new(raw)

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end

    it 'recursively deserializes hashes' do
      ref = random_ref_string

      data = { test: { :@obj => { :@ref => { id: ref } } } }
      obj = { test: Fauna::Ref.new(ref) }

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end

    it 'recursively deserializes arrays' do
      ref1 = random_ref_string
      ref2 = random_ref_string

      data = [{ :@ref => { id: ref1 } }, { :@ref => { id: ref2 } }]
      obj = [Fauna::Ref.new(ref1), Fauna::Ref.new(ref2)]

      expect(Fauna::FaunaJson.deserialize(data)).to eq(obj)
    end
  end

  describe '#to_json' do
    it 'serializes ref' do
      ref = random_ref_string

      data = { :@ref => { id: ref } }
      obj = Fauna::Ref.new(ref)

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end

    it 'serializes set' do
      ref = random_ref_string

      data = { :@ref => { id: ref } }
      obj = Fauna::Ref.new(ref)

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end

    it 'serializes query' do
      query = { lambda: 'a', expr: { add: [{ var: 'a' }, 1] } }
      obj = Fauna::QueryV.new(query)

      expect(Fauna::FaunaJson.serialize(obj)).to eq(:@query => query)
    end

    it 'serializes expr' do
      data = { a: random_string, b: random_number }
      obj = Fauna::Query::Expr.new(data)

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end

    it 'serializes time' do
      data = { :@ts => '1970-01-01T00:00:00.000000000Z' }
      obj = Time.at(0).utc

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end

    it 'serializes date' do
      data = { :@date => '1970-01-01' }
      obj = Date.new(1970, 1, 1)

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end

    it 'serializes bytes' do
      raw = random_bytes

      data = { :@bytes => Base64.urlsafe_encode64(raw) }
      obj = Fauna::Bytes.new(raw)

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end

    it 'recursively serializes hashes' do
      ref = random_ref_string
      terms = random_string

      data = { a: { time: { :@ts => '1970-01-01T00:00:00.000000000Z' } }, b: { :@set => { match: { :@ref => { id: ref } }, terms: terms } } }
      obj = { a: { time: Time.at(0).utc }, b: Fauna::SetRef.new(match: Fauna::Ref.new(ref), terms: terms) }

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end

    it 'recursively serializes arrays' do
      ref1 = random_ref_string
      ref2 = random_ref_string

      data = [{ :@ref => { id: ref1 } }, { :@ref => { id: ref2 } }]
      obj = [Fauna::Ref.new(ref1), Fauna::Ref.new(ref2)]

      expect(Fauna::FaunaJson.serialize(obj)).to eq(data)
    end
  end
end
