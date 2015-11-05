require File.expand_path('../test_helper', __FILE__)

class ObjectsTest < FaunaTest
  def setup
    super

    @ref = Ref.new 'classes/frogs', '123'
    @json_ref = '{"@ref":"classes/frogs/123"}'

    @index = Ref.new 'indexes', 'frogs_by_size'
    @json_index = '{"@ref":"indexes/frogs_by_size"}'
  end

  def parse_json(json)
    Client.new.send :deserialize, FaunaDecode.new.send(:json_load, json)
  end

  def to_json(obj)
    obj.to_json
  end

  def test_ref
    assert_equal @ref, parse_json(@json_ref)
    assert_equal @json_ref, to_json(@ref)

    blobs = Ref.new 'classes/blobs'
    ref = Ref.new blobs, '123'
    assert_equal blobs, ref.to_class
    assert_equal '123', ref.id

    keys = Ref.new 'keys'
    assert_equal keys, keys.to_class
    assert_raises(FaunaError) do
      keys.id
    end

    ref = Ref.new keys, '123'
    assert_equal keys, ref.to_class
    assert_equal '123', ref.id
  end

  def test_set
    match = Set.new Query.match(@ref, @index)
    json_match = "{\"@set\":{\"match\":#{@json_ref},\"index\":#{@json_index}}}"
    assert_equal match, parse_json(json_match)
    assert_equal json_match, to_json(match)
  end

  def test_event
    assert_equal '{"ts":123}', to_json(Event.new(123, nil, nil))
    event_json = '{"ts":123,"action":"create","resource":{"@ref":"classes/frogs/123"}}'
    assert_equal event_json, to_json(Event.new(123, 'create', @ref))
  end
end
