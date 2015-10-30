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
  end

  def test_let_var
    assert_query 1, Fauna::Query.let({ x: 1 }, Fauna::Query.var(:x))
  end

  def test_if
    assert_query 't', Fauna::Query.if(true, 't', 'f')
    assert_query 'f', Fauna::Query.if(false, 't', 'f')
  end

  def test_do
    instance = create_instance
    assert_query 1, Fauna::Query.do(Fauna::Query.delete(instance[:ref]), 1)
    assert_query false, Fauna::Query.exists(instance[:ref])
  end

  def test_object
    # unlike quote, contents are evaluated
    assert_query(
      { x: 1 },
      Fauna::Query.object(x: Fauna::Query.let({ x: 1 }, Fauna::Query.var(:x))))
  end

  def test_quote
    quoted = Fauna::Query.let({ x: 1 }, Fauna::Query.var('x'))
    assert_query quoted, Fauna::Query.quote(quoted)
  end

  def test_lambda
    assert_equal Fauna::Query.lambda { |a| Fauna::Query.add(a, a) },
      lambda: 'auto0',
      expr: { add: [{ var: 'auto0' }, { var: 'auto0' }] }

    lambda = Fauna::Query.lambda do |a|
      Fauna::Query.lambda do |b|
        Fauna::Query.lambda { |c| [a, b, c] }
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
    assert_raises 'Error' do
      Fauna::Query.lambda do
        fail 'Error'
      end
    end
    # We'll still be using `auto0` because Fauna::Query.lambda handles errors.
    assert_equal Fauna::Query.lambda { |a| a },
      lambda: 'auto0',
      expr: { var: 'auto0' }
  end

  # Test that lambda_query works in simultaneous threads.
  def test_lambda_multithreaded
    events = []
    thread_a = Thread.new do
      q = Fauna::Query.lambda do |a|
        events << 0
        sleep 1
        events << 2
        a
      end
      assert_equal({ lambda: 'auto0', expr: { var: 'auto0' } }, q)
    end
    thread_b = Thread.new do
      assert_equal({ lambda: 'auto0', expr: { var: 'auto0' } }, Fauna::Query.lambda { |a| a })
      events << 1
    end
    thread_a.join
    thread_b.join
    assert_equal [0, 1, 2], events
  end

  def test_map
    # This is also test_lambda_expr (can't test that alone)
    double = Fauna::Query.lambda do |x|
      Fauna::Query.multiply([2, x])
    end
    assert_query [2, 4, 6], Fauna::Query.map(double, [1, 2, 3])

    get_n = Fauna::Query.lambda do |x|
      Fauna::Query.select([:data, :n], Fauna::Query.get(x))
    end
    page = Fauna::Query.paginate(n_set(1))
    ns = Fauna::Query.map(get_n, page)
    assert_query({ data: [1, 1] }, ns)
  end

  def test_foreach
    refs = [create_instance[:ref], create_instance[:ref]]
    delete = Fauna::Query.lambda do |x|
      Fauna::Query.delete(x)
    end
    client.query Fauna::Query.foreach(delete, refs)
    refs.each do |ref|
      assert_query false, Fauna::Query.exists(ref)
    end
  end

  def test_get
    instance = create_instance
    assert_query instance, Fauna::Query.get(instance[:ref])
  end

  def test_paginate
    test_set = n_set 1
    assert_query({ data: [@ref_n1, @ref_n1m1] }, Fauna::Query.paginate(test_set))
    assert_query(
      { after: @ref_n1m1, data: [@ref_n1] },
      Fauna::Query.paginate(test_set, size: 1))

    response_with_sources = {
      data: [
        { sources: [Fauna::Set.new(test_set)], value: @ref_n1 },
        { sources: [Fauna::Set.new(test_set)], value: @ref_n1m1 },
      ],
    }
    assert_query response_with_sources, Fauna::Query.paginate(test_set, sources: true)
  end

  def test_exists
    ref = create_instance[:ref]
    assert_query true, Fauna::Query.exists(ref)
    client.query Fauna::Query.delete(ref)
    assert_query false, Fauna::Query.exists(ref)
  end

  def test_count
    create_instance n: 123
    create_instance n: 123
    instances = n_set 123
    # `count` is currently only approximate. Should be 2.
    assert client.query(Fauna::Query.count(instances)).is_a? Integer
  end

  def test_create
    instance = create_instance
    assert instance.include? :ref
    assert instance.include? :ts
    assert_equal @class_ref, instance[:class]
  end

  def test_update
    ref = create_instance[:ref]
    got = client.query Fauna::Query.update(
      ref,
      Fauna::Query.quote(data: { m: 1 }))
    assert_equal({ n: 0, m: 1 }, got[:data])
  end

  def test_replace
    ref = create_instance[:ref]
    got = client.query Fauna::Query.replace(
      ref,
      Fauna::Query.quote(data: { m: 1 }))
    assert_equal({ m: 1 }, got[:data])
  end

  def test_delete
    ref = create_instance[:ref]
    client.query Fauna::Query.delete(ref)
    assert_equal false, client.query(Fauna::Query.exists(ref))
  end

  def test_match
    set = n_set(1)
    assert_equal [@ref_n1, @ref_n1m1], get_set_contents(set)
  end

  def test_union
    set = Fauna::Query.union n_set(1), m_set(1)
    assert_equal [@ref_n1, @ref_m1, @ref_n1m1], get_set_contents(set)
  end

  def test_intersection
    set = Fauna::Query.intersection n_set(1), m_set(1)
    assert_equal [@ref_n1m1], get_set_contents(set)
  end

  def test_difference
    set = Fauna::Query.difference n_set(1), m_set(1)
    assert_equal [@ref_n1], get_set_contents(set)
  end

  def test_join
    referenced = [create_instance(n: 12)[:ref], create_instance(n: 12)[:ref]]
    referencers = [create_instance(m: referenced[0])[:ref], create_instance(m: referenced[1])[:ref]]

    source = n_set 12
    assert_equal referenced, get_set_contents(source)

    # For each obj with n=12, get the set of elements whose data.m refers to it.
    set = Fauna::Query.join(
      source,
      Fauna::Query.lambda do |x|
        Fauna::Query.match(x, @m_index_ref)
      end)
    assert_equal referencers, get_set_contents(set)
  end

  def test_equals
    assert_query true, Fauna::Query.equals(1, 1, 1)
    assert_query false, Fauna::Query.equals(1, 1, 2)
    assert_query true, Fauna::Query.equals(1)
    assert_bad_query Fauna::Query.equals
  end

  def test_concat
    assert_query 'abc', Fauna::Query.concat('a', 'b', 'c')
    assert_query '', Fauna::Query.concat
  end

  def test_contains
    obj = Fauna::Query.quote a: { b: 1 }
    assert_query true, Fauna::Query.contains([:a, :b], obj)
    assert_query true, Fauna::Query.contains(:a, obj)
    assert_query false, Fauna::Query.contains([:a, :c], obj)
  end

  def test_select
    obj = Fauna::Query.quote a: { b: 1 }
    assert_query({ b: 1 }, Fauna::Query.select(:a, obj))
    assert_query 1, Fauna::Query.select([:a, :b], obj)
    assert_query nil, Fauna::Query.select(:c, obj, default: nil)
    assert_raises(Fauna::NotFound) do
      client.query Fauna::Query.select(:c, obj)
    end
  end

  def test_select_array
    arr = [1, 2, 3]
    assert_query 3, Fauna::Query.select(2, arr)
    assert_raises(Fauna::NotFound) do
      client.query Fauna::Query.select(3, arr)
    end
  end

  def test_add
    assert_query 10, Fauna::Query.add(2, 3, 5)
    assert_bad_query Fauna::Query.add
  end

  def test_multiply
    assert_query 30, Fauna::Query.multiply(2, 3, 5)
    assert_bad_query Fauna::Query.multiply
  end

  def test_subtract
    assert_query(-6, Fauna::Query.subtract(2, 3, 5))
    assert_query 2, Fauna::Query.subtract(2)
    assert_bad_query Fauna::Query.subtract
  end

  def test_divide
    assert_query 2.0 / 15, Fauna::Query.divide(2.0, 3, 5)
    assert_query 2, Fauna::Query.divide(2)
    assert_bad_query Fauna::Query.divide(1, 0)
    assert_bad_query Fauna::Query.divide
  end

  def test_varargs
    # Works for lists too
    assert_query 10, Fauna::Query.add([2, 3, 5])
    # Works for a variable equal to a list
    assert_query 10, Fauna::Query.let({ x: [2, 3, 5] }, Fauna::Query.add(Fauna::Query.var(:x)))
  end

private

  def n_set(n)
    Fauna::Query.match n, @n_index_ref
  end

  def m_set(m)
    Fauna::Query.match m, @m_index_ref
  end

  def create_instance(data = {})
    data[:n] ||= 0
    client.query Fauna::Query.create(@class_ref, Fauna::Query.quote(data: data))
  end

  def get_set_contents(set)
    client.query(Fauna::Query.paginate(set, size: 1000))[:data]
  end

  def assert_query(expected, query)
    assert_equal expected, client.query(query)
  end

  def assert_bad_query(query)
    assert_raises(Fauna::BadRequest) do
      client.query query
    end
  end
end
