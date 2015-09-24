require File.expand_path('../test_helper', __FILE__)

class ObjectsTest < FaunaTest
  def setup
    super

    @ref = Fauna::Ref.new 'classes/frogs', '123'
    @json_ref = '{"@ref":"classes/frogs/123"}'

    @index = Fauna::Ref.new 'indexes', 'frogs_by_size'
    @json_index = '{"@ref":"indexes/frogs_by_size"}'
  end

  def parse_json(json)
    Fauna::Client.new.send :deserialize, JSON.load(json)
  end

  def to_json(obj)
    obj.to_json
  end

  def test_ref # rubocop:disable Metrics/AbcSize
    assert_equal @ref, parse_json(@json_ref)
    assert_equal @json_ref, to_json(@ref)

    blobs = Fauna::Ref.new 'classes/blobs'
    ref = Fauna::Ref.new blobs, '123'
    assert_equal blobs, ref.to_class
    assert_equal '123', ref.id

    keys = Fauna::Ref.new 'keys'
    assert_equal keys, keys.to_class
    assert_raises(Fauna::FaunaError) do
      keys.id
    end

    ref = Fauna::Ref.new keys, '123'
    assert_equal keys, ref.to_class
    assert_equal '123', ref.id
  end

  def test_set
    match = Fauna::Set.new Fauna::Query.match(@ref, @index)
    json_match = "{\"@set\":{\"match\":#{@json_ref},\"index\":#{@json_index}}}"
    assert_equal match, parse_json(json_match)
    assert_equal json_match, to_json(match)
  end

  def test_event
    assert_equal '{"ts":123}', to_json(Fauna::Event.new(123, nil, nil))
    event_json = '{"ts":123,"action":"create","resource":{"@ref":"classes/frogs/123"}}'
    assert_equal event_json, to_json(Fauna::Event.new(123, 'create', @ref))
  end
end
