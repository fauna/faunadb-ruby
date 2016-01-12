require File.expand_path('../test_helper', __FILE__)

class QueryTest < FaunaTest

  Widgets = Ref.new('classes/widgets')
  WidgetsByN = Ref.new('indexes/widgets_by_n')
  WidgetsByM = Ref.new('indexes/widgets_by_m')
  Thimbles = Ref.new('classes/thimbles')

  def setup
    super

    client.post('classes', name: 'widgets')

    client.post(
      'indexes',
      name: 'widgets_by_n',
      source: Widgets,
      path: 'data.n',
      active: true)

    client.post(
      'indexes',
      name: 'widgets_by_m',
      source: Widgets,
      path: 'data.m',
      active: true)

    @ref_n1 = create_instance(n: 1)[:ref]
    @ref_m1 = create_instance(m: 1)[:ref]
    @ref_n1m1 = create_instance(n: 1, m: 1)[:ref]

    client.post('classes', name: 'thimbles')
  end

  def test_query_helper_method_missing
    foo = 'foo'
    assert_equal 'foo', Fauna.query { foo }
  end

  def test_let_var
    assert_equal 1, client.query { let({ x: 1 }, var(:x)) }
  end

  def test_if
    assert_equal 't', client.query { if_(true, 't', 'f') }
    assert_equal 'f', client.query { if_(false, 't', 'f') }
  end

  def test_do
    instance = create_instance
    assert_equal 1, client.query { do_(delete(instance[:ref]), 1) }
    assert_equal false, client.query { exists(instance[:ref]) }
  end

  def test_object
    assert_equal({ x: 1 }, client.query { object(x: let({ x: 1 }, var(:x))) })
  end

  def test_quote
    quoted = Fauna.query { let({ x: 1 }, var('x')) }
    assert_equal quoted, client.query { quote(quoted) }
  end

  def test_lambda
    assert_raises ArgumentError do
      Fauna.query { lambda {} }
    end

    q = Fauna.query { lambda { |a| add(a, a) } }
    expr = { lambda: :a, expr: { add: [{ var: :a }, { var: :a }] } }

    assert_equal expr, q
  end

  def test_lambda_multiple_args
    q = Fauna.query { lambda { |a, b| [b, a] } }
    expr = { lambda: [:a, :b], expr: [{ var: :b }, { var: :a }] }

    assert_equal expr, q
    assert_equal [[2, 1], [4, 3]], client.query { map([[1, 2], [3, 4]], q) }
  end

  def test_lambda_expr_vs_block
    # Use manual lambda: 2 args, no block
    assert_equal [2, 4, 6], client.query { map([1, 2, 3], lambda_expr(:a, multiply(2, var(:a)))) }
    # Use lambda: 2 args, lambda
    assert_equal [2, 4, 6], client.query { map([1, 2, 3], lambda { |a| multiply 2, a }) }
    # Use block lambda: only 1 arg
    assert_equal [2, 4, 6], client.query { map [1, 2, 3] { |a| multiply 2, a } }
  end

  def test_map
    assert_equal [2, 4, 6], client.query { map([1, 2, 3]) { |a| multiply 2, a } }

    assert_equal({ data: [1, 1] }, client.query do
      map paginate(match(WidgetsByN, 1)), lambda { |a| select([:data, :n], get(a)) }
    end)
  end

  def test_foreach
    refs = [create_instance[:ref], create_instance[:ref]]
    client.query { foreach(refs) { |a| delete a } }

    refs.each do |ref|
      assert_equal false, client.query { exists(ref) }
    end
  end

  def test_filter
    assert_equal [2, 4], client.query { filter([1, 2, 3, 4]) { |a| equals modulo(a, 2), 0 } }

    # Works on page too
    assert_equal({ data: [@ref_n1m1] }, client.query do
      filter(paginate(match(WidgetsByN, 1))) do |a|
        contains [:data, :m], get(a)
      end
    end)
  end

  def test_take
    assert_equal [1], client.query { take(1, [1, 2]) }
    assert_equal [1, 2], client.query { take(3, [1, 2]) }
    assert_equal [], client.query { take(-1, [1, 2]) }
  end

  def test_drop
    assert_equal [2], client.query { drop(1, [1, 2]) }
    assert_equal [], client.query { drop(3, [1, 2]) }
    assert_equal [1, 2], client.query { drop(-1, [1, 2]) }
  end

  def test_prepend
    assert_equal [1, 2, 3, 4, 5, 6], client.query { prepend([1, 2, 3], [4, 5, 6]) }
  end

  def test_append
    assert_equal [1, 2, 3, 4, 5, 6], client.query { append([4, 5, 6], [1, 2, 3]) }
  end

  def test_get
    instance = create_instance
    assert_equal instance, client.query { get(instance[:ref]) }
  end

  def test_paginate
    test_set = Query.match(WidgetsByN, 1)
    control = [@ref_n1, @ref_n1m1]
    assert_equal({ data: control }, client.query { paginate(test_set) })

    data = []
    page1 = client.query { paginate(test_set, size: 1) }
    data += page1[:data]
    page2 = client.query { paginate(test_set, size: 1, after: page1[:after]) }
    data += page2[:data]
    assert_equal(control, data)

    response_with_sources = {
      data: [
        { sources: [Set.new(match: WidgetsByN, terms: 1)], value: @ref_n1 },
        { sources: [Set.new(match: WidgetsByN, terms: 1)], value: @ref_n1m1 },
      ]
    }
    assert_equal response_with_sources, client.query { paginate(test_set, sources: true) }
  end

  def test_exists
    ref = create_instance[:ref]
    assert_equal true, client.query { exists(ref) }
    client.query { delete(ref) }
    assert_equal false, client.query { exists(ref) }
  end

  def test_count
    create_instance n: 123
    create_instance n: 123
    instances = Query.match(WidgetsByN, 123)
    # `count` is currently only approximate. Should be 2.
    assert client.query(Query.count(instances)).is_a? Integer
  end

  def test_create
    instance = create_instance
    assert instance.include? :ref
    assert instance.include? :ts
    assert_equal Widgets, instance[:class]
  end

  def test_update
    ref = create_instance[:ref]
    got = client.query { update(ref, quote(data: { m: 1 })) }
    assert_equal({ n: 0, m: 1 }, got[:data])
  end

  def test_replace
    ref = create_instance[:ref]
    got = client.query { replace(ref, quote(data: { m: 1 })) }
    assert_equal({ m: 1 }, got[:data])
  end

  def test_delete
    ref = create_instance[:ref]
    client.query Query.delete(ref)
    assert_equal false, client.query(Query.exists(ref))
  end

  def test_insert
    instance = create_thimble weight: 1
    ref = instance[:ref]
    ts = instance[:ts]
    prev_ts = ts - 1
    # Add previous event
    client.query { insert(ref, prev_ts, :create, quote(data: { weight: 0 })) }

    # Get version from previous event
    old = client.query { get(ref, ts: prev_ts) }
    assert_equal({ weight: 0 }, old[:data])
  end

  def test_remove
    instance = create_thimble
    ref = instance[:ref]

    # Change it
    new_instance = client.query { replace(ref, quote(data: { weight: 1 })) }
    assert_equal new_instance, client.query { get(ref) }

    # Delete that event
    client.query { remove(ref, new_instance[:ts], :create) }

    # Assert that it was undone
    assert_equal instance, client.query { get(ref) }
  end

  def test_match
    set = Fauna.query { match(WidgetsByN, 1) }
    assert_equal [@ref_n1, @ref_n1m1], get_set_contents(set)
  end

  def test_union
    set = Fauna.query { union match(WidgetsByN, 1), match(WidgetsByM, 1) }
    assert_equal [@ref_n1, @ref_m1, @ref_n1m1], get_set_contents(set)
  end

  def test_intersection
    set = Fauna.query { intersection match(WidgetsByN, 1), match(WidgetsByM, 1) }
    assert_equal [@ref_n1m1], get_set_contents(set)
  end

  def test_difference
    set = Fauna.query { difference match(WidgetsByN, 1), match(WidgetsByM, 1) }
    assert_equal [@ref_n1], get_set_contents(set)
  end

  def test_join
    referenced = [create_instance(n: 12)[:ref], create_instance(n: 12)[:ref]]
    referencers = [create_instance(m: referenced[0])[:ref], create_instance(m: referenced[1])[:ref]]

    source = Query.match(WidgetsByN, 12)
    assert_equal referenced, get_set_contents(source)

    # For each obj with n=12, get the set of elements whose data.m refers to it.
    set = Query.join source do |a|
      Query.match WidgetsByM, a
    end
    assert_equal referencers, get_set_contents(set)
  end

  def test_concat
    assert_equal 'abc', client.query { concat(['a', 'b', 'c']) }
    assert_equal '', client.query { concat([]) }
    assert_equal 'a.b.c', client.query { concat(['a', 'b', 'c'], '.') }
  end

  def test_casefold
    assert_equal 'hen wen', client.query { casefold('Hen Wen') }
  end

  def test_time
    # `.round 9` is necessary because MRI 1.9.3 stores with greater precision than just nanoseconds.
    # This cuts it down to just nanoseconds so that the times compare as equal.
    time = Time.at(0, 123_456.789).round 9
    assert_equal time, client.query { time('1970-01-01T00:00:00.123456789Z') }

    # 'now' refers to the current time.
    assert client.query(Query.time('now')).is_a?(Time)
  end

  def test_epoch
    secs = RandomHelper.random_number
    assert_equal Time.at(secs).utc, client.query { epoch(secs, 'second') }
    nanos = RandomHelper.random_number
    assert_equal Time.at(Rational(nanos, 1_000_000_000)).utc, client.query { epoch(nanos, 'nanosecond') }
  end

  def test_date
    assert_equal Date.new(1970, 1, 1), client.query { date('1970-01-01') }
  end

  def test_equals
    assert_equal true, client.query { equals(1, 1, 1) }
    assert_equal false, client.query { equals(1, 1, 2) }
    assert_equal true, client.query { equals(1) }
  end

  def test_contains
    obj = { a: { b: 1 } }
    assert_equal true, client.query { contains([:a, :b], quote(obj)) }
    assert_equal true, client.query { contains(:a, quote(obj)) }
    assert_equal false, client.query { contains([:a, :c], quote(obj)) }
  end

  def test_select
    obj = { a: { b: 1 } }
    assert_equal({ b: 1 }, client.query { select(:a, quote(obj)) })
    assert_equal 1, client.query { select([:a, :b], quote(obj)) }
    assert_equal nil, client.query { select(:c, quote(obj), default: nil) }
    assert_raises(NotFound) do
      client.query { select(:c, quote(obj)) }
    end
  end

  def test_select_array
    arr = [1, 2, 3]
    assert_equal 3, client.query { select(2, arr) }
    assert_raises(NotFound) do
      client.query { select(3, arr) }
    end
  end

  def test_add
    assert_equal 10, client.query { add(2, 3, 5) }
  end

  def test_multiply
    assert_equal 30, client.query { multiply(2, 3, 5) }
  end

  def test_subtract
    assert_equal -6, client.query { subtract(2, 3, 5) }
    assert_equal 2, client.query { subtract(2) }
  end

  def test_divide
    assert_equal 2.0 / 15, client.query { divide(2.0, 3, 5) }
    assert_equal 2, client.query { divide(2) }
  end

  def test_modulo
    assert_equal 1, client.query { modulo(5, 2) }
    # This is (15 % 10) % 2
    assert_equal 1, client.query { modulo(15, 10, 2) }
    assert_equal 2, client.query { modulo(2) }
  end

  def test_and
    assert_equal false, client.query { and_(true, true, false) }
    assert_equal true, client.query { and_(true, true, true) }
    assert_equal true, client.query { and_(true) }
    assert_equal false, client.query { and_(false) }
  end

  def test_or
    assert_equal true, client.query { or_(false, false, true) }
    assert_equal false, client.query { or_(false, false, false) }
    assert_equal true, client.query { or_(true) }
    assert_equal false, client.query { or_(false) }
  end

  def test_not
    assert_equal false, client.query { not_(true) }
    assert_equal true, client.query { not_(false) }
  end

  def test_varargs
    # Works for lists too
    assert_equal 10, client.query { add([2, 3, 5]) }
    # Works for a variable equal to a list
    assert_equal 10, client.query { let({ x: [2, 3, 5] }, add(var(:x))) }
  end

private

  def create_instance(data = {})
    data[:n] ||= 0
    client.query { create Widgets, quote(data: data) }
  end

  def create_thimble(data = {})
    client.query { create Thimbles, quote(data: data) }
  end

  def get_set_contents(set)
    client.query { paginate(set, size: 1000) }[:data]
  end
end
