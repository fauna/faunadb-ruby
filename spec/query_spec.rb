RSpec.describe Fauna::Query do
  before(:all) do
    create_test_db
    @test_class = client.query { create ref('classes'), name: 'query_test' }[:ref]

    index_x = client.query do
      create ref('indexes'), name: 'query_by_x', source: @test_class, terms: [{ path: 'data.x' }]
    end
    index_y = client.query do
      create ref('indexes'), name: 'query_by_y', source: @test_class, terms: [{ path: 'data.y' }]
    end

    wait_for_index(index_x[:ref], index_y[:ref])

    @test_by_x = index_x[:ref]
    @test_by_y = index_y[:ref]
  end

  after(:all) do
    destroy_test_db
  end

  # Alias for creating test class instance with provided data
  def create_instance(data = {})
    client.query { create(@test_class, data: data) }
  end

  # Helper to collect all the contents of a set
  def get_set_data(set, params = {})
    data = []

    page = client.query { paginate(set, params) }
    data += page[:data]
    while page.key? :after
      page = client.query { paginate(set, params.merge(after: page[:after])) }
      data += page[:data]
    end

    data
  end

  describe Fauna::Query::Expr do
    describe '#to_s' do
      it 'converts to string' do
        expr = Fauna::Query::Expr.new(
          add: Fauna::Query::Expr.new(
            [1, Fauna::Query::Expr.new(divide: Fauna::Query::Expr.new([4, 2]))]
          )
        )
        as_string = 'Expr({:add=>Expr([1, Expr({:divide=>Expr([4, 2])})])})'

        expect(expr.to_s).to eq(as_string)
      end
    end

    describe '#==' do
      it 'equals identical expression' do
        expr1 = Fauna::Query::Expr.new(add: Fauna::Query::Expr.new([1, 2]))
        expr2 = Fauna::Query::Expr.new(add: Fauna::Query::Expr.new([1, 2]))

        expect(expr1).to eq(expr2)
      end

      it 'does not equal different expression' do
        expr1 = Fauna::Query::Expr.new(add: Fauna::Query::Expr.new([1, 2]))
        expr2 = Fauna::Query::Expr.new(
          add: Fauna::Query::Expr.new(
            [1, Fauna::Query::Expr.new(divide: Fauna::Query::Expr.new([4, 2]))]
          )
        )

        expect(expr1).not_to eq(expr2)
      end
    end
  end

  describe '#expr' do
    it 'maintains lexical scope' do
      def test_method
        'foo'
      end
      test_var = 'bar'

      expect(Fauna::Query.expr { test_method }).to eq('foo')
      expect(Fauna::Query.expr { test_var }).to eq('bar')
    end

    it 'recursively wraps hashes' do
      expr = Fauna::Query.expr { { x: 1, y: { foo: 2 }, z: add(1, 2) } }
      query = { object: { x: 1, y: { object: { foo: 2 } }, z: { add: [1, 2] } } }

      expect(to_json(expr)).to eq(to_json(query))
    end

    it 'recursively wraps special types' do
      expr = Fauna::Query.expr { { x: { y: Time.at(0).utc } } }
      query = { object: { x: { object: { y: { :@ts => '1970-01-01T00:00:00.000000000Z' } } } } }

      expect(to_json(expr)).to eq(to_json(query))
    end

    it 'round-trips special types', skip: 'Support for auto-escaping of special types is deferred' do
      expect(client.query { { '@ref' => 'foo' } }).to eq(:@ref => 'foo')
    end
  end

  describe '#ref' do
    it 'returns a ref from a string' do
      str = random_ref_string
      expect(Fauna::Query.ref(str)).to eq(Fauna::Ref.new(str))
    end

    it 'constructs a ref' do
      expect(client.query { ref(@test_class, '123') }).to eq(Fauna::Ref.new('classes/query_test/123'))
      expect(client.query { ref(@test_class, next_id) }.value).to match(%r{^classes/query_test/\d+$})
    end
  end

  describe '#object' do
    it 'wraps fields in object' do
      data = { a: random_string, b: random_number }
      expect(Fauna::Query.object(data).raw).to eq(object: data)
    end
  end

  describe '#let' do
    it 'performs let with expression' do
      x = random_number
      expect(client.query { let({ x: x }, var(:x)) }).to eq(x)
    end

    it 'performs let with block' do
      x = random_number
      expect(client.query { let(x: x) { x } }).to eq(x)
    end
  end

  describe '#var' do
    it 'creates a var' do
      name = random_string
      expect(Fauna::Query.var(name).raw).to eq(var: name)
    end
  end

  describe '#if_' do
    it 'performs an if' do
      expect(client.query { if_(true, 't', 'f') }).to eq('t')
      expect(client.query { if_(false, 't', 'f') }).to eq('f')
    end
  end

  describe '#do_' do
    it 'performs do' do
      instance = create_instance
      expect(client.query { do_(delete(instance[:ref]), 1) }).to eq(1)
      expect(client.query { exists instance[:ref] }).to be(false)
    end
  end

  describe '#lambda' do
    it 'raises when block takes no arguments' do
      expect { Fauna::Query.lambda {} }.to raise_error(ArgumentError)
    end

    it 'raises when block takes splat argument' do
      expect { Fauna::Query.lambda { |*vars| add(vars) } }.to raise_error(ArgumentError)
    end

    it 'performs lambda from single argument' do
      expr = Fauna::Query.expr { lambda { |a| add(a, a) } }
      query = { lambda: :a, expr: { add: [{ var: :a }, { var: :a }] } }

      expect(to_json(expr)).to eq(to_json(query))
      expect(client.query { map([1, 2, 3], expr) }).to eq([2, 4, 6])
    end

    it 'performs lambda from multiple arguments' do
      expr = Fauna::Query.expr { lambda { |a, b| [b, a] } }
      query = { lambda: [:a, :b], expr: [{ var: :b }, { var: :a }] }

      expect(to_json(expr)).to eq(to_json(query))
      expect(client.query { map([[1, 2], [3, 4]], expr) }).to eq([[2, 1], [4, 3]])
    end
  end

  describe '#lambda_expr' do
    it 'performs lambda from expression' do
      expr = Fauna::Query.expr { lambda_expr(:a, add(var(:a), var(:a))) }
      query = { lambda: :a, expr: { add: [{ var: :a }, { var: :a }] } }

      expect(to_json(expr)).to eq(to_json(query))
      expect(client.query { map([1, 2, 3], expr) }).to eq([2, 4, 6])
    end

    it 'destructures single element arrays' do
      expr = Fauna::Query.expr { lambda_expr([:a], add(var(:a), var(:a))) }
      query = { lambda: [:a], expr: { add: [{ var: :a }, { var: :a }] } }

      expect(to_json(expr)).to eq(to_json(query))
      expect(client.query { map([[1], [2], [3]], expr) }).to eq([2, 4, 6])
    end
  end

  describe '#map' do
    it 'performs map from expression' do
      input = (1..3).collect { random_number }
      output = input.collect { |x| 2 * x }

      expect(client.query { map(input, lambda { |a| multiply 2, a }) }).to eq(output)
    end

    it 'performs map from block' do
      input = (1..3).collect { random_number }
      output = input.collect { |x| 2 * x }

      expect(client.query { map(input) { |a| multiply 2, a } }).to eq(output)
    end
  end

  describe '#foreach' do
    before(:each) do
      @refs = (1..3).collect { create_instance[:ref] }

      # Sanity check
      expect(client.query { @refs.collect { |ref| exists ref } }).to eq(@refs.collect { true })
    end

    it 'performs foreach from expression' do
      client.query { foreach @refs, lambda { |a| delete a } }

      expect(client.query { @refs.collect { |ref| exists ref } }).to eq(@refs.collect { false })
    end

    it 'performs foreach from block' do
      client.query { foreach(@refs) { |a| delete a } }

      expect(client.query { @refs.collect { |ref| exists ref } }).to eq(@refs.collect { false })
    end
  end

  describe '#filter' do
    it 'performs filter from expression' do
      expect(client.query { filter([1, 2, 3, 4], lambda { |a| equals modulo(a, 2), 0 }) }).to eq([2, 4])
    end

    it 'performs filter from block' do
      expect(client.query { filter([1, 2, 3, 4]) { |a| equals modulo(a, 2), 0 } }).to eq([2, 4])
    end
  end

  describe '#take' do
    it 'performs take' do
      expect(client.query { take(1, [1, 2]) }).to eq([1])
      expect(client.query { take(3, [1, 2]) }).to eq([1, 2])
      expect(client.query { take(-1, [1, 2]) }).to eq([])
    end
  end

  describe '#drop' do
    it 'performs drop' do
      expect(client.query { drop(1, [1, 2]) }).to eq([2])
      expect(client.query { drop(3, [1, 2]) }).to eq([])
      expect(client.query { drop(-1, [1, 2]) }).to eq([1, 2])
    end
  end

  describe '#prepend' do
    it 'performs prepend' do
      expect(client.query { prepend([4, 5, 6], [1, 2, 3]) }).to eq([1, 2, 3, 4, 5, 6])
    end
  end

  describe '#append' do
    it 'performs append' do
      expect(client.query { append([1, 2, 3], [4, 5, 6]) }).to eq([1, 2, 3, 4, 5, 6])
    end
  end

  describe '#get' do
    it 'performs get' do
      instance = create_instance

      expect(client.query { get instance[:ref] }).to eq(instance)
    end
  end

  describe '#paginate' do
    before do
      @x_value = random_number
      @x_refs = (1..3).collect { create_instance(x: @x_value)[:ref] }
    end

    it 'performs paginate' do
      set = Fauna::Query.match(@test_by_x, @x_value)

      expect(get_set_data(set, size: 1)).to eq(@x_refs)
    end

    it 'performs paginate with sources' do
      response = {
        data: @x_refs.collect do |ref|
          { sources: [Fauna::SetRef.new(match: @test_by_x, terms: @x_value)], value: ref }
        end
      }

      expect(client.query { paginate(match(@test_by_x, @x_value), sources: true) }).to eq(response)
    end
  end

  describe '#exists' do
    it 'performs exists' do
      ref = create_instance[:ref]

      expect(client.query { exists ref }).to be(true)
      client.query { delete ref }
      expect(client.query { exists ref }).to be(false)

      # Sanity check
      expect { client.query { get ref } }.to raise_error(Fauna::NotFound)
    end
  end

  describe '#count' do
    before do
      @x_value = random_number
      @x_refs = (1..3).collect { create_instance(x: @x_value)[:ref] }
    end

    it 'performs count' do
      set = Fauna::Query.match(@test_by_x, @x_value)

      # Count is only approximate; should be equal to @x_refs.length
      expect(client.query { count set }).to be_a(Integer)
    end
  end

  describe '#create' do
    it 'performs create' do
      instance = client.query { create(@test_class, {}) }

      expect(instance[:class]).to eq(@test_class)
      expect(client.query { exists instance[:ref] }).to be(true)
    end
  end

  describe '#update' do
    it 'performs update' do
      x = random_number
      y = random_number
      ref = create_instance(x: x)[:ref]

      instance = client.query { update(ref, data: { y: y }) }
      expect(instance[:data]).to eq(x: x, y: y)
    end
  end

  describe '#replace' do
    it 'performs replace' do
      x = random_number
      y = random_number
      ref = create_instance(x: x)[:ref]

      instance = client.query { replace(ref, data: { y: y }) }
      expect(instance[:data]).to eq(y: y)
    end
  end

  describe '#delete' do
    it 'performs delete' do
      ref = create_instance[:ref]

      client.query { delete ref }
      expect(client.query { exists ref }).to be(false)
    end
  end

  describe '#insert' do
    it 'performs insert' do
      instance = create_instance
      ref = instance[:ref]
      ts = instance[:ts]

      prev_ts = ts - 1
      value = random_number
      client.query { insert(ref, prev_ts, :create, data: { x: value }) }

      expect(client.query { get(ref, ts: prev_ts) }[:data]).to eq(x: value)
    end
  end

  describe '#remove' do
    it 'performs remove' do
      # Create the instance
      instance = create_instance
      ref = instance[:ref]

      # Change the instance
      new_instance = client.query { replace(ref, data: { x: random_number }) }
      expect(client.query { get(ref) }).to eq(new_instance)

      # Delete the event
      client.query { remove(ref, new_instance[:ts], :create) }

      # Assert it changed
      expect(client.query { get(ref) }).to eq(instance)
    end
  end

  describe '#create_class' do
    it 'creates a class' do
      # Create a class
      ref = client.query { create_class(name: random_string) }[:ref]

      # Assert it was created
      expect(client.query { exists(ref) }).to be(true)
    end
  end

  describe '#create_index' do
    it 'creates an index' do
      # Create an index
      class_ref = client.query { create(ref('classes'), name: random_string) }[:ref]
      ref = client.query { create_index(name: random_string, source: class_ref) }[:ref]

      # Assert it was created
      expect(client.query { exists(ref) }).to be(true)
    end
  end

  describe '#create_database' do
    it 'creates a database' do
      # Create a database
      ref = admin_client.query { create_database(name: random_string) }[:ref]

      # Assert it was created
      expect(admin_client.query { exists(ref) }).to be(true)
    end
  end

  describe '#create_key' do
    it 'creates a key' do
      # Create a key
      db_ref = admin_client.query { create(ref('databases'), name: random_string) }[:ref]
      ref = admin_client.query { create_key(database: db_ref, role: 'server') }[:ref]

      # Assert it was created
      expect(admin_client.query { exists(ref) }).to be(true)
    end
  end

  describe 'sets' do
    before do
      @x_value = random_number
      @y_value = random_number

      @ref_x = create_instance(x: @x_value)[:ref]
      @ref_y = create_instance(y: @y_value)[:ref]
      @ref_xy = create_instance(x: @x_value, y: @y_value)[:ref]
    end

    describe '#match' do
      it 'performs match' do
        set = Fauna::Query.expr { match(@test_by_x, @x_value) }
        expect(get_set_data(set)).to contain_exactly(@ref_x, @ref_xy)
      end
    end

    describe '#union' do
      it 'performs union' do
        set = Fauna::Query.expr { union(match(@test_by_x, @x_value), match(@test_by_y, @y_value)) }
        expect(get_set_data(set)).to contain_exactly(@ref_x, @ref_y, @ref_xy)
      end
    end

    describe '#intersection' do
      it 'performs intersection' do
        set = Fauna::Query.expr { intersection(match(@test_by_x, @x_value), match(@test_by_y, @y_value)) }
        expect(get_set_data(set)).to contain_exactly(@ref_xy)
      end
    end

    describe '#difference' do
      it 'performs difference' do
        set = Fauna::Query.expr { difference(match(@test_by_x, @x_value), match(@test_by_y, @y_value)) }
        expect(get_set_data(set)).to contain_exactly(@ref_x)
      end
    end
  end

  describe '#distinct' do
    before do
      over_z = client.query do
        create ref('indexes'), name: 'query_over_z', source: @test_class, values: [{ path: 'data.z' }]
      end
      wait_for_index(over_z[:ref])
      @test_over_z = over_z[:ref]

      @refs = []
      @refs << client.query { create @test_class, data: { z: 0 } }[:ref]
      @refs << client.query { create @test_class, data: { z: 1 } }[:ref]
      @refs << client.query { create @test_class, data: { z: 1 } }[:ref]
    end

    it 'performs distinct' do
      set = Fauna::Query.match(@test_over_z)
      distinct = Fauna::Query.distinct(set)

      expect(get_set_data(set)).to eq([0, 1, 1])
      expect(get_set_data(distinct)).to eq([0, 1])
    end
  end

  describe '#join' do
    before do
      @x_value = random_number
      @join_refs = (1..3).collect { create_instance(x: @x_value)[:ref] }
      @assoc_refs = @join_refs.collect { |ref| create_instance(y: ref)[:ref] }
    end

    context 'with expression' do
      it 'performs join' do
        source = Fauna::Query.match(@test_by_x, @x_value)
        expect(get_set_data(source)).to eq(@join_refs)

        # Get associated refs
        set = Fauna::Query.expr { join(source, lambda { |a| match(@test_by_y, a) }) }
        expect(get_set_data(set)).to eq(@assoc_refs)
      end
    end

    context 'with block' do
      it 'performs join' do
        source = Fauna::Query.match(@test_by_x, @x_value)
        expect(get_set_data(source)).to eq(@join_refs)

        # Get associated refs
        set = Fauna::Query.expr { join(source) { |a| match(@test_by_y, a) } }
        expect(get_set_data(set)).to eq(@assoc_refs)
      end
    end

    context 'with index' do
      it 'performs join' do
        source = Fauna::Query.match(@test_by_x, @x_value)
        expect(get_set_data(source)).to eq(@join_refs)

        # Get associated refs
        set = Fauna::Query.expr { join(source, @test_by_y) }
        expect(get_set_data(set)).to eq(@assoc_refs)
      end
    end
  end

  describe 'authentication' do
    before do
      @password = random_string
      @user = client.query { create @test_class, credentials: { password: @password } }
    end

    describe '#login' do
      it 'performs login' do
        token = client.query { login @user[:ref], password: @password }
        user_client = get_client secret: token[:secret]

        expect(user_client.query { select(:ref, get(ref('tokens/self'))) }).to eq(token[:ref])
      end
    end

    describe '#logout' do
      it 'performs logout' do
        token = client.query { login @user[:ref], password: @password }
        user_client = get_client secret: token[:secret]

        expect(user_client.query { logout true }).to be(true)
      end
    end

    describe '#identify' do
      it 'performs identify' do
        expect(client.query { identify(@user[:ref], @password) }).to be(true)
      end
    end
  end

  describe '#concat' do
    it 'performs concat' do
      expect(client.query { concat ['a', 'b', 'c'] }).to eq('abc')
      expect(client.query { concat [] }).to eq('')
    end

    it 'performs concat with separator' do
      expect(client.query { concat(['a', 'b', 'c'], '.') }).to eq('a.b.c')
    end
  end

  describe '#casefold' do
    it 'performs casefold' do
      expect(client.query { casefold 'Hen Wen' }).to eq('hen wen')
    end
  end

  describe '#test' do
    it 'performs time' do
      # `.round 9` is necessary because MRI 1.9.3 stores with greater precision than just nanoseconds.
      # This cuts it down to just nanoseconds so that the times compare as equal.
      time = Time.at(0, 123_456.789).round 9
      expect(client.query { time '1970-01-01T00:00:00.123456789Z' }).to eq(time)

      # 'now' refers to the current time.
      expect(client.query { time 'now' }).to be_a(Time)
    end
  end

  describe '#epoch' do
    it 'performs epoch for seconds' do
      secs = random_number
      expect(client.query { epoch(secs, 'second') }).to eq(Time.at(secs).utc)
    end

    it 'performs epoch for nanoseconds' do
      nanos = random_number
      expect(client.query { epoch(nanos, 'nanosecond') }).to eq(Time.at(Rational(nanos, 1_000_000_000)).utc)
    end
  end

  describe '#date' do
    it 'performs date' do
      expect(client.query { date('1970-01-01') }).to eq(Date.new(1970, 1, 1))
    end
  end

  describe '#next_id' do
    it 'gets a new id' do
      expect(client.query { next_id }).to be_a(String)
    end
  end

  describe '#equals' do
    it 'performs equals' do
      expect(client.query { equals(1, 1, 1) }).to be(true)
      expect(client.query { equals(1, 1, 2) }).to be(false)
      expect(client.query { equals 1 }).to be(true)
    end
  end

  describe '#contains' do
    it 'performs contains' do
      obj = { a: { b: 1 } }

      expect(client.query { contains([:a, :b], obj) }).to be(true)
      expect(client.query { contains(:a, obj) }).to be(true)
      expect(client.query { contains([:a, :c], obj) }).to be(false)
    end
  end

  describe '#select' do
    it 'performs select with hash' do
      obj = { a: { b: 1 } }

      expect(client.query { select(:a, obj) }).to eq(b: 1)
      expect(client.query { select([:a, :b], obj) }).to eq(1)
      expect(client.query { select(:c, obj, default: nil) }).to be_nil
      expect { client.query { select(:c, obj) } }.to raise_error(Fauna::NotFound)
    end

    it 'performs select with array' do
      arr = [1, 2, 3]

      expect(client.query { select(2, arr) }).to eq(3)
      expect { client.query { select(3, arr) } }.to raise_error(Fauna::NotFound)
    end
  end

  describe '#add' do
    it 'performs add' do
      expect(client.query { add(2, 3, 5) }).to eq(10)
    end
  end

  describe '#multiply' do
    it 'performs multiply' do
      expect(client.query { multiply(2, 3, 5) }).to eq(30)
    end
  end

  describe '#subtract' do
    it 'performs subtract' do
      expect(client.query { subtract(2, 3, 5) }).to eq(-6)
      expect(client.query { subtract(2) }).to eq(2)
    end
  end

  describe '#divide' do
    it 'performs divide' do
      expect(client.query { divide(2.0, 3, 5) }).to eq(2.0 / 15)
      expect(client.query { divide(2) }).to eq(2)
    end
  end

  describe '#modulo' do
    it 'performs modulo' do
      expect(client.query { modulo(5, 2) }).to eq(1)
      expect(client.query { modulo(15, 10, 2) }).to eq(1)
      expect(client.query { modulo(2) }).to eq(2)
    end
  end

  describe '#lt' do
    it 'performs lt' do
      expect(client.query { lt(1, 2) }).to be(true)
      expect(client.query { lt(2, 2) }).to be(false)
    end
  end

  describe '#lte' do
    it 'performs lte' do
      expect(client.query { lte(1, 1) }).to be(true)
      expect(client.query { lte(2, 1) }).to be(false)
    end
  end

  describe '#gt' do
    it 'performs gt' do
      expect(client.query { gt(2, 1) }).to be(true)
      expect(client.query { gt(2, 2) }).to be(false)
    end
  end

  describe '#gte' do
    it 'performs gte' do
      expect(client.query { gte(2, 2) }).to be(true)
      expect(client.query { gte(2, 3) }).to be(false)
    end
  end

  describe '#and_' do
    it 'performs and' do
      expect(client.query { and_(true, true, false) }).to be(false)
      expect(client.query { and_(true, true, true) }).to be(true)
      expect(client.query { and_(true) }).to be(true)
      expect(client.query { and_(false) }).to be(false)
    end
  end

  describe '#or_' do
    it 'performs or' do
      expect(client.query { or_(false, false, true) }).to be(true)
      expect(client.query { or_(false, false, false) }).to be(false)
      expect(client.query { or_(true) }).to be(true)
      expect(client.query { or_(false) }).to be(false)
    end
  end

  describe '#not_' do
    it 'performs not' do
      expect(client.query { not_(true) }).to be(false)
      expect(client.query { not_(false) }).to be(true)
    end
  end
end
