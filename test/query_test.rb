require File.expand_path('../test_helper', __FILE__)

class QueryTest < FaunaTest
  def setup
    super

    @class_ref = client.post('classes', name: 'widgets')[:ref]
    @n_index_ref = client.post(
      'indexes',
      name: 'widgets_by_n',
      source: @class_ref,
      path: 'data.n',
      active: true)[:ref]

    @m_index_ref = client.post(
      'indexes',
      name: 'widgets_by_m',
      source: @class_ref,
      path: 'data.m',
      active: true)[:ref]

    @ref_n1 = create_instance(n: 1)[:ref]
    @ref_m1 = create_instance(m: 1)[:ref]
    @ref_n1m1 = create_instance(n: 1, m: 1)[:ref]

    @thimble_class_ref = client.post('classes', name: 'thimbles')[:ref]
  end

  def test_let_var
    assert_query 1, Query.let({ x: 1 }, Query.var(:x))
  end

  def test_if
    assert_query 't', Query.if(true, 't', 'f')
    assert_query 'f', Query.if(false, 't', 'f')
  end

  def test_do
    instance = create_instance
    assert_query 1, Query.do(Query.delete(instance[:ref]), 1)
    assert_query false, Query.exists(instance[:ref])
  end

  def test_object
    # unlike quote, contents are evaluated
    assert_query(
      { x: 1 },
      Query.object(x: Query.let({ x: 1 }, Query.var(:x))))
  end

  def test_quote
    quoted = Query.let({ x: 1 }, Query.var('x'))
    assert_query quoted, Query.quote(quoted)
  end

  def test_lambda
    assert_equal Query.lambda { |a| Query.add(a, a) },
      lambda: 'auto0',
      expr: { add: [{ var: 'auto0' }, { var: 'auto0' }] }

    lambda = Query.lambda do |a|
      Query.lambda do |b|
        Query.lambda { |c| [a, b, c] }
      end
    end
    assert_equal lambda,
      lambda: 'auto0',
      expr: {
        lambda: 'auto1',
        expr: {
          lambda: 'auto2',
          expr: [{ var: 'auto0' }, { var: 'auto1' }, { var: 'auto2' }],
        },
      }

    # Error in function should not affect future queries.
    assert_raises RuntimeError do
      Query.lambda do
        fail 'Error'
      end
    end
    # We'll still be using `auto0` because Query.lambda handles errors.
    assert_equal Query.lambda { |a| a },
      lambda: 'auto0',
      expr: { var: 'auto0' }
  end

  # Test that lambda_query works in simultaneous threads.
  def test_lambda_multithreaded
    events = []
    thread_a = Thread.new do
      q = Query.lambda do |a|
        events << 0
        sleep 1
        events << 2
        a
      end
      assert_equal({ lambda: 'auto0', expr: { var: 'auto0' } }, q)
    end
    thread_b = Thread.new do
      sleep 0.5
      assert_equal({ lambda: 'auto0', expr: { var: 'auto0' } }, Query.lambda { |a| a })
      events << 1
    end
    thread_a.join
    thread_b.join
    assert_equal [0, 1, 2], events
  end

  def test_lambda_expr_vs_block
    # Use manual lambda: 2 args, no block
    assert_query [2, 4, 6], Query.map([1, 2, 3], Query.lambda_expr('a',
      Query.multiply(2, Query.var('a'))))
    # Use block lambda: only 1 arg
    assert_query [2, 4, 6], (Query.map([1, 2, 3]) do |a|
      Query.multiply 2, a
    end)
  end

  def test_lambda_pattern
    array_lambda = Query.lambda_pattern [:a, :b] do |args|
      [args[:b], args[:a]]
    end
    assert_equal Query.lambda_expr([:a, :b], [Query.var(:b), Query.var(:a)]), array_lambda
    assert_query [[2, 1], [4, 3]], Query.map([[1, 2], [3, 4]], array_lambda)

    object_lambda = Query.lambda_pattern(alpha: :a, beta: :b) do |args|
      [args[:b], args[:a]]
    end
    expected_object_lambda = Query.lambda_expr(
      { alpha: :a, beta: :b },
      [Query.var(:b), Query.var(:a)])
    assert_equal expected_object_lambda, object_lambda
    object_data = Query.quote [{ alpha: 1, beta: 2 }, { alpha: 3, beta: 4 }]
    assert_query [[2, 1], [4, 3]], Query.map(object_data, object_lambda)

    mixed_pattern = { alpha: [:a, :b], beta: { gamma: :c, delta: :d } }
    mixed_lambda = Query.lambda_pattern(mixed_pattern) do |args|
      [args[:a], args[:b], args[:c], args[:d]]
    end
    expected_mixed_lambda = Query.lambda_expr(
      mixed_pattern,
      [Query.var(:a), Query.var(:b), Query.var(:c), Query.var(:d)])
    assert_equal expected_mixed_lambda, mixed_lambda
    mixed_data = Query.quote [{ alpha: [1, 2], beta: { gamma: 3, delta: 4 } }]
    assert_query [[1, 2, 3, 4]], Query.map(mixed_data, mixed_lambda)

    # Allows ignored variables.
    ignore_lambda = Query.lambda_pattern([:foo, :_, :bar]) do |args|
      [args[:bar], args[:foo]]
    end
    expected_ignore_lambda = Query.lambda_expr([:foo, :_, :bar], [Query.var(:bar), Query.var(:foo)])
    assert_equal expected_ignore_lambda, ignore_lambda
    assert_query [[3, 1], [6, 4]], Query.map([[1, 2, 3], [4, 5, 6]], ignore_lambda)

    # Extra array elements are ignored.
    assert_query [[2, 1]], Query.map([[1, 2, 3]], array_lambda)

    # Object patterns must have all keys.
    assert_bad_query Query.map([{ alpha: 1, beta: 2 }], Query.lambda_pattern(alpha: :a) { || 0 })

    # Lambda generator fails for bad pattern.
    assert_raises(InvalidQuery) do
      Query.lambda_pattern(alpha: 0) { || 0 }
    end
  end

  def test_map
    assert_query [2, 4, 6], (Query.map([1, 2, 3]) do |a|
      Query.multiply 2, a
    end)

    page = Query.paginate(n_set(1))
    ns = Query.map page do |a|
      Query.select([:data, :n], Query.get(a))
    end
    assert_query({ data: [1, 1] }, ns)
  end

  def test_foreach
    refs = [create_instance[:ref], create_instance[:ref]]
    client.query(Query.foreach(refs) do |a|
      Query.delete a
    end)
    refs.each do |ref|
      assert_query false, Query.exists(ref)
    end
  end

  def test_filter
    assert_query [2, 4], (Query.filter([1, 2, 3, 4]) do |a|
      Query.equals Query.modulo(a, 2), 0
    end)

    # Works on page too
    page = Query.paginate n_set(1)
    refs_with_m = Query.filter(page) do |a|
      Query.contains [:data, :m], Query.get(a)
    end
    assert_query({ data: [@ref_n1m1] }, refs_with_m)
  end

  def test_take
    assert_query [1], Query.take(1, [1, 2])
    assert_query [1, 2], Query.take(3, [1, 2])
    assert_query [], Query.take(-1, [1, 2])
  end

  def test_drop
    assert_query [2], Query.drop(1, [1, 2])
    assert_query [], Query.drop(3, [1, 2])
    assert_query [1, 2], Query.drop(-1, [1, 2])
  end

  def test_prepend
    assert_query [1, 2, 3, 4, 5, 6], Query.prepend([1, 2, 3], [4, 5, 6])
    # Fails for non-array.
    assert_bad_query Query.prepend([1, 2], 'foo')
  end

  def test_append
    assert_query [1, 2, 3, 4, 5, 6], Query.append([4, 5, 6], [1, 2, 3])
    # Fails for non-array.
    assert_bad_query Query.append([1, 2], 'foo')
  end

  def test_get
    instance = create_instance
    assert_query instance, Query.get(instance[:ref])
  end

  def test_paginate
    test_set = n_set 1
    assert_query({ data: [@ref_n1, @ref_n1m1] }, Query.paginate(test_set))
    assert_query(
      { after: [@ref_n1m1], data: [@ref_n1] },
      Query.paginate(test_set, size: 1))

    response_with_sources = {
      data: [
        { sources: [Set.new(test_set)], value: @ref_n1 },
        { sources: [Set.new(test_set)], value: @ref_n1m1 },
      ],
    }
    assert_query response_with_sources, Query.paginate(test_set, sources: true)
  end

  def test_exists
    ref = create_instance[:ref]
    assert_query true, Query.exists(ref)
    client.query Query.delete(ref)
    assert_query false, Query.exists(ref)
  end

  def test_count
    create_instance n: 123
    create_instance n: 123
    instances = n_set 123
    # `count` is currently only approximate. Should be 2.
    assert client.query(Query.count(instances)).is_a? Integer
  end

  def test_create
    instance = create_instance
    assert instance.include? :ref
    assert instance.include? :ts
    assert_equal @class_ref, instance[:class]
  end

  def test_update
    ref = create_instance[:ref]
    got = client.query Query.update(
      ref,
      Query.quote(data: { m: 1 }))
    assert_equal({ n: 0, m: 1 }, got[:data])
  end

  def test_replace
    ref = create_instance[:ref]
    got = client.query Query.replace(
      ref,
      Query.quote(data: { m: 1 }))
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
    inserted = Query.quote(data: { weight: 0 })
    add = Query.insert(ref, prev_ts, :create, inserted)
    client.query add
    # Test alternate syntax
    assert_equal add, Query.insert_event(Event.new(ref, prev_ts, :create), inserted)

    # Get version from previous event
    old = client.query Query.get(ref, ts: prev_ts)
    assert_equal({ weight: 0 }, old[:data])
  end

  def test_remove
    instance = create_thimble
    ref = instance[:ref]

    # Change it
    new_instance = client.query(Query.replace(ref, Query.quote(data: { weight: 1 })))
    assert_equal new_instance, client.query(Query.get(ref))

    # Delete that event
    remove = Query.remove(ref, new_instance[:ts], :create)
    client.query remove
    # Test alternate syntax
    assert_equal remove, Query.remove_event(Event.new(ref, new_instance[:ts], :create))

    # Assert that it was undone
    assert_equal instance, client.query(Query.get(ref))
  end

  def test_match
    set = n_set(1)
    assert_equal [@ref_n1, @ref_n1m1], get_set_contents(set)
  end

  def test_union
    set = Query.union n_set(1), m_set(1)
    assert_equal [@ref_n1, @ref_m1, @ref_n1m1], get_set_contents(set)
  end

  def test_intersection
    set = Query.intersection n_set(1), m_set(1)
    assert_equal [@ref_n1m1], get_set_contents(set)
  end

  def test_difference
    set = Query.difference n_set(1), m_set(1)
    assert_equal [@ref_n1], get_set_contents(set)
  end

  def test_join
    referenced = [create_instance(n: 12)[:ref], create_instance(n: 12)[:ref]]
    referencers = [create_instance(m: referenced[0])[:ref], create_instance(m: referenced[1])[:ref]]

    source = n_set 12
    assert_equal referenced, get_set_contents(source)

    # For each obj with n=12, get the set of elements whose data.m refers to it.
    set = Query.join source do |a|
      Query.match a, @m_index_ref
    end
    assert_equal referencers, get_set_contents(set)
  end

  def test_concat
    assert_query 'abc', Query.concat(['a', 'b', 'c'])
    assert_query '', Query.concat([])
    assert_query 'a.b.c', Query.concat(['a', 'b', 'c'], '.')
  end

  def test_casefold
    assert_query 'hen wen', Query.casefold('Hen Wen')
  end

  def test_time
    # `.round 9` is necessary because MRI 1.9.3 stores with greater precision than just nanoseconds.
    # This cuts it down to just nanoseconds so that the times compare as equal.
    time = Time.at(0, 123_456.789).round 9
    assert_query time, Query.time('1970-01-01T00:00:00.123456789Z')

    # 'now' refers to the current time.
    assert client.query(Query.time('now')).is_a?(Time)
  end

  def test_epoch
    secs = RandomHelper.random_number
    assert_query Time.at(secs).utc, Query.epoch(secs, 'second')
    nanos = RandomHelper.random_number
    assert_query Time.at(Rational(nanos, 1_000_000_000)).utc, Query.epoch(nanos, 'nanosecond')
  end

  def test_date
    assert_query Date.new(1970, 1, 1), Query.date('1970-01-01')
  end

  def test_equals
    assert_query true, Query.equals(1, 1, 1)
    assert_query false, Query.equals(1, 1, 2)
    assert_query true, Query.equals(1)
    assert_bad_query Query.equals
  end

  def test_contains
    obj = Query.quote a: { b: 1 }
    assert_query true, Query.contains([:a, :b], obj)
    assert_query true, Query.contains(:a, obj)
    assert_query false, Query.contains([:a, :c], obj)
  end

  def test_select
    obj = Query.quote a: { b: 1 }
    assert_query({ b: 1 }, Query.select(:a, obj))
    assert_query 1, Query.select([:a, :b], obj)
    assert_query nil, Query.select(:c, obj, default: nil)
    assert_raises(NotFound) do
      client.query Query.select(:c, obj)
    end
  end

  def test_select_array
    arr = [1, 2, 3]
    assert_query 3, Query.select(2, arr)
    assert_raises(NotFound) do
      client.query Query.select(3, arr)
    end
  end

  def test_add
    assert_query 10, Query.add(2, 3, 5)
    assert_bad_query Query.add
  end

  def test_multiply
    assert_query 30, Query.multiply(2, 3, 5)
    assert_bad_query Query.multiply
  end

  def test_subtract
    assert_query(-6, Query.subtract(2, 3, 5))
    assert_query 2, Query.subtract(2)
    assert_bad_query Query.subtract
  end

  def test_divide
    assert_query 2.0 / 15, Query.divide(2.0, 3, 5)
    assert_query 2, Query.divide(2)
    assert_bad_query Query.divide(1, 0)
    assert_bad_query Query.divide
  end

  def test_modulo
    assert_query 1, Query.modulo(5, 2)
    # This is (15 % 10) % 2
    assert_query 1, Query.modulo(15, 10, 2)
    assert_query 2, Query.modulo(2)
    assert_bad_query Query.modulo(1, 0)
    assert_bad_query Query.modulo
  end

  def test_and
    assert_query false, Query.and(true, true, false)
    assert_query true, Query.and(true, true, true)
    assert_query true, Query.and(true)
    assert_query false, Query.and(false)
    assert_bad_query Query.and
  end

  def test_or
    assert_query true, Query.or(false, false, true)
    assert_query false, Query.or(false, false, false)
    assert_query true, Query.or(true)
    assert_query false, Query.or(false)
    assert_bad_query Query.or
  end

  def test_not
    assert_query false, Query.not(true)
    assert_query true, Query.not(false)
  end

  def test_varargs
    # Works for lists too
    assert_query 10, Query.add([2, 3, 5])
    # Works for a variable equal to a list
    assert_query 10, Query.let({ x: [2, 3, 5] }, Query.add(Query.var(:x)))
  end

private

  def n_set(n)
    Query.match n, @n_index_ref
  end

  def m_set(m)
    Query.match m, @m_index_ref
  end

  def create_instance(data = {})
    data[:n] ||= 0
    client.query Query.create(@class_ref, Query.quote(data: data))
  end

  def create_thimble(data = {})
    client.query Query.create(@thimble_class_ref, Query.quote(data: data))
  end

  def get_set_contents(set)
    client.query(Query.paginate(set, size: 1000))[:data]
  end

  def assert_query(expected, query)
    assert_equal expected, client.query(query)
  end

  def assert_bad_query(query)
    assert_raises(BadRequest) do
      client.query query
    end
  end
end
