require File.expand_path('../test_helper', __FILE__)

class QueryTest < FaunaTest

  Widgets = Query.ref('classes/widgets')
  WidgetsByN = Query.ref('indexes/widgets_by_n')
  WidgetsByM = Query.ref('indexes/widgets_by_m')
  NOfWidgets = Query.ref('indexes/n_of_widgets')
  Thimbles = Query.ref('classes/thimbles')

  def setup
    super

    client.query { create ref('classes'), name: 'widgets' }

    client.query do
      create ref('indexes'),
             name: 'widgets_by_n',
             source: Widgets,
             path: 'data.n',
             active: true
    end

    client.query do
      create ref('indexes'),
             name: 'widgets_by_m',
             source: Widgets,
             path: 'data.m',
             active: true
    end

    client.query do
      create ref('indexes'),
             name: 'n_of_widgets',
             source: Widgets,
             values: [{ path: 'data.n' }],
             active: true
    end

    @ref_n1 = create_instance(n: 1)[:ref]
    @ref_m1 = create_instance(m: 1)[:ref]
    @ref_n1m1 = create_instance(n: 1, m: 1)[:ref]

    client.query { create(ref('classes'), name: 'thimbles') }
  end

  def test_expr_to_s
    query = Query.expr { add 1, divide(4, 2) }
    assert_equal 'Expr({:add=>Expr([1, Expr({:divide=>Expr([4, 2])})])})', query.to_s
  end

  def foo_method
    'foo'
  end

  def test_query_helper_lexical_scope
    bar_var = 'bar'
    assert_equal 'foo', Query.expr { foo_method }
    assert_equal 'bar', Query.expr { bar_var }
  end

  def test_let_var
    assert_equal 1, client.query { let(x: 1) { x } }
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

  def test_hash_conversion
    q = Query.expr { { x: 1, y: { foo: 2 }, z: add(1, 2) } }
    expr = { object: { x: 1, y: { object: { foo: 2 } }, z: { add: [1, 2] } } }
    assert_equal expr.to_json, q.to_json

    q = Query.expr { { x: { y: Time.at(0) } } }
    expr = { object: { x: { object: { y: { :@ts => Time.at(0).utc.iso8601(9) } } } } }
    assert_equal expr.to_json, q.to_json
  end

  def test_object
    assert_equal({ x: 1 }, client.query { object(x: let(x: 1) { x }) })
  end

  def test_lambda
    assert_raises ArgumentError do
      Query.expr { lambda {} }
    end

    q = Query.expr { lambda { |a| add(a, a) } }
    expr = { lambda: :a, expr: { add: [{ var: :a }, { var: :a }] } }

    assert_equal expr.to_json, q.to_json
  end

  def test_lambda_multiple_args
    q = Query.expr { lambda { |a, b| [b, a] } }
    expr = { lambda: [:a, :b], expr: [{ var: :b }, { var: :a }] }

    assert_equal expr.to_json, q.to_json
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
        { sources: [SetRef.new(match: WidgetsByN, terms: 1)], value: @ref_n1 },
        { sources: [SetRef.new(match: WidgetsByN, terms: 1)], value: @ref_n1m1 },
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
    got = client.query { update(ref, data: { m: 1 }) }
    assert_equal({ n: 0, m: 1 }, got[:data])
  end

  def test_replace
    ref = create_instance[:ref]
    got = client.query { replace(ref, data: { m: 1 }) }
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
    client.query { insert(ref, prev_ts, :create, data: { weight: 0 }) }

    # Get version from previous event
    old = client.query { get(ref, ts: prev_ts) }
    assert_equal({ weight: 0 }, old[:data])
  end

  def test_remove
    instance = create_thimble
    ref = instance[:ref]

    # Change it
    new_instance = client.query { replace(ref, data: { weight: 1 }) }
    assert_equal new_instance, client.query { get(ref) }

    # Delete that event
    client.query { remove(ref, new_instance[:ts], :create) }

    # Assert that it was undone
    assert_equal instance, client.query { get(ref) }
  end

  def test_match
    set = Query.expr { match(WidgetsByN, 1) }
    assert_equal [@ref_n1, @ref_n1m1], get_set_contents(set)
  end

  def test_union
    set = Query.expr { union match(WidgetsByN, 1), match(WidgetsByM, 1) }
    assert_equal [@ref_n1, @ref_m1, @ref_n1m1], get_set_contents(set)
  end

  def test_intersection
    set = Query.expr { intersection match(WidgetsByN, 1), match(WidgetsByM, 1) }
    assert_equal [@ref_n1m1], get_set_contents(set)
  end

  def test_difference
    set = Query.expr { difference match(WidgetsByN, 1), match(WidgetsByM, 1) }
    assert_equal [@ref_n1], get_set_contents(set)
  end

  def test_distinct
    set = Query.match(NOfWidgets)
    assert_equal [0, 1, 1], get_set_contents(set)
    distinct_set = Query.distinct(set)
    assert_equal [0, 1], get_set_contents(distinct_set)
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

  def test_login_logout
    widg = client.query { create Widgets, credentials: { password: 'sekrit' } }
    token = client.query { login widg[:ref], password: 'sekrit' }
    widg_client = get_client secret: token[:secret]

    assert_equal widg[:ref], widg_client.query { select(:ref, get(ref('classes/widgets/self'))) }

    assert_equal true, widg_client.query { logout true }
  end

  def test_identify
    widg = client.query { create Widgets, credentials: { password: 'sekrit' } }
    assert_equal true, client.query { identify widg[:ref], 'sekrit' }
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
    assert_equal true, client.query { contains([:a, :b], obj) }
    assert_equal true, client.query { contains(:a, obj) }
    assert_equal false, client.query { contains([:a, :c], obj) }
  end

  def test_select
    obj = { a: { b: 1 } }
    assert_equal({ b: 1 }, client.query { select(:a, obj) })
    assert_equal 1, client.query { select([:a, :b], obj) }
    assert_equal nil, client.query { select(:c, obj, default: nil) }
    assert_raises(NotFound) do
      client.query { select(:c, obj) }
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

  def test_lt
    assert_equal true, client.query { lt 1, 2 }
  end

  def test_lte
    assert_equal true, client.query { lte 1, 1 }
  end

  def test_gt
    assert_equal true, client.query { gt 2, 1 }
  end

  def test_gte
    assert_equal true, client.query { gte 1, 1 }
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
    assert_equal 10, client.query { let(x: [2, 3, 5]) { add(x) } }
  end

private

  def create_instance(data = {})
    data[:n] ||= 0
    client.query { create Widgets, data: data }
  end

  def create_thimble(data = {})
    client.query { create Thimbles, data: data }
  end

  def get_set_contents(set)
    client.query { paginate(set, size: 1000) }[:data]
  end
end
