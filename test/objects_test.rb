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
    FaunaJson.deserialize FaunaJson.json_load(json)
  end

  def to_json(obj)
    FaunaJson.to_json obj
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
    assert_raises(ArgumentError) do
      keys.id
    end

    ref = Ref.new keys, '123'
    assert_equal keys, ref.to_class
    assert_equal '123', ref.id
  end

  def test_set
    match = SetRef.new match: @index, terms: @ref
    json_match = "{\"@set\":{\"match\":#{@json_index},\"terms\":#{@json_ref}}}"
    assert_equal match, parse_json(json_match)
    assert_equal json_match, to_json(match)
  end

  def test_ts
    test_ts = Time.at(0).utc
    test_ts_json = '{"@ts":"1970-01-01T00:00:00.000000000Z"}'
    assert_equal test_ts_json, to_json(test_ts)
    assert_equal test_ts, parse_json(test_ts_json)
  end

  def test_date
    test_date = Date.new(1970, 1, 1)
    test_date_json = '{"@date":"1970-01-01"}'
    assert_equal test_date_json, to_json(test_date)
    assert_equal test_date, parse_json(test_date_json)
  end
end
