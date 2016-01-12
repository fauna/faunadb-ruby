module Fauna

  ##
  # Build a query expression.
  #
  # Allows for unscoped calls to Fauna::Query methods within the
  # provided block. The block should return the constructed query
  # expression.
  #
  # Example: <code>Fauna.query { add(1, 2, subtract(3, 2)) }</code>
  def self.query(&block)
    return nil if block.nil?

    dsl = Query::QueryDSLContext.new

    Query.send :expr, DSLContext.eval_dsl(dsl, &block)
  end

  ##
  # Helpers modeling the FaunaDB \Query language.
  #
  # Helpers can be used directly to build a query expression, or called via a more concise dsl notation.
  #
  # Example:
  #
  #   Fauna::Query.create(Fauna::Query.ref('classes', 'spells'), { data: { name: 'Magic Missile' } })
  #
  # DSL equivalent:
  #
  #   Fauna.query { create(ref('classes', 'spells'), { data: { name: 'Magic Missile' } }) }
  #
  # Query expressions are evaluated by passing them to Client#query, however Client#query may be directly passed a DSL block:
  #
  #   client.query { create(ref('classes', 'spells'), { data: { name: 'Magic Missile' } }) }
  module Query
    extend self

    # :nodoc:
    class QueryDSLContext < DSLContext
      include Query
    end

    # :section: Values

    ##
    # Construct a ref value
    #
    # Reference: {FaunaDB Values}[https://faunadb.com/documentation/queries#values]
    def ref(*args)
      Ref.new(*args)
    end

    ##
    # An object expression
    #
    # Query expression constructs can also take a regular ruby object, so the following are equivalent:
    #
    #   Fauna.query { object(x: 1, y: add(1, 2)) }
    #   Fauna.query { { x: 1, y: add(1, 2) } }
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def object(fields)
      Expr.new object: expr_values(fields)
    end


    # :section: Basic forms

    ##
    # A let expression
    #
    # Only one of \in_expr or blk should be provided.
    #
    # Block example: <code>Fauna.query { let(x: 2) { add(1, x) } }</code>.
    #
    # Expression example: <code>Fauna.query { let({ x: 2 }, add(1, var(:x))) }</code>.
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def let(vars, in_expr = nil, &blk)
      in_ = if blk.nil?
        in_expr
      else
        dsl = QueryDSLContext.new
        dslcls = (class << dsl; self; end)

        vars.keys.each do |v|
          dslcls.send(:define_method, v) { var(v) }
        end

        DSLContext.eval_dsl(dsl, &blk)
      end

      Expr.new let: expr_values(vars), in: expr(in_)
    end

    ##
    # A var expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def var(name)
      Expr.new var: expr(name)
    end

    ##
    # An if expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def if_(condition, then_, else_)
      Expr.new :if => expr(condition), :then => expr(then_), :else => expr(else_)
    end

    ##
    # A do expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def do_(*expressions)
      Expr.new :do => varargs(expressions)
    end

    ##
    # A lambda expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    #
    # This form generates ::var objects for you, and is called like:
    #
    #   Query.lambda do |a|
    #     Query.add a, a
    #   end
    #   # Produces: {lambda: :a, expr: {add: [{var: :a}, {var: :a}]}}
    #
    # Query functions requiring lambdas can be passed blocks without explicitly calling ::lambda.
    #
    # You can also use ::lambda_expr and ::var directly.
    # +block+::
    #   Takes one or more ::var expressions and uses them to construct an expression.
    #   If this takes more than one argument, the lambda destructures an array argument.
    #   (To destructure single-element arrays use ::lambda_expr.)
    def lambda(&block)
      vars = block_parameters block
      case vars.length
      when 0
        fail ArgumentError, 'Block must take at least 1 argument.'
      when 1
        # When there's only 1 parameter, don't use an array pattern.
        lambda_expr vars[0], block.call(var(vars[0]))
      else
        lambda_expr vars, block.call(*(vars.map { |v| var(v) }))
      end
    end

    ##
    # A raw lambda expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    #
    # See also ::lambda.
    def lambda_expr(var, expr)
      Expr.new lambda: expr(var), expr: expr(expr)
    end

    # :section: Collections

    ##
    # A map expression
    #
    # Only one of `lam` or `blk` should be provided.
    # For example: <code>Fauna.query { map(collection) { |a| add a, 1 } }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def map(collection, lam = nil, &blk)
      Expr.new map: expr(lam || blk), collection: expr(collection)
    end

    ##
    # A foreach expression
    #
    # Only one of `lam` or `blk` should be provided.
    # For example: <code>Fauna.query { foreach(collection) { |a| delete a } }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def foreach(collection, lam = nil, &blk)
      Expr.new foreach: expr(lam || blk), collection: expr(collection)
    end

    ##
    # A filter expression
    #
    # Only one of `lam` or `blk` should be provided.
    # For example: <code>Fauna.query { filter(collection) { |a| equals a, 1 } }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def filter(collection, lam = nil, &blk)
      Expr.new filter: expr(lam || blk), collection: expr(collection)
    end

    ##
    # A take expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def take(number, collection)
      Expr.new take: expr(number), collection: expr(collection)
    end

    ##
    # A drop expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def drop(number, collection)
      Expr.new drop: expr(number), collection: expr(collection)
    end

    ##
    # A prepend expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def prepend(elements, collection)
      Expr.new prepend: expr(elements), collection: expr(collection)
    end

    ##
    # An append expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def append(elements, collection)
      Expr.new append: expr(elements), collection: expr(collection)
    end

    # :section: Read functions

    ##
    # A get expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def get(ref, params = {})
      Expr.new expr_values(params).merge(get: expr(ref))
    end

    ##
    # A paginate expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def paginate(set, params = {})
      Expr.new expr_values(params).merge(paginate: expr(set))
    end

    ##
    # An exists expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def exists(ref, params = {})
      Expr.new expr_values(params).merge(exists: expr(ref))
    end

    ##
    # A count expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def count(set, params = {})
      Expr.new expr_values(params).merge(count: expr(set))
    end

    # :section: Write functions

    ##
    # A create expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def create(class_ref, params)
      Expr.new create: expr(class_ref), params: expr(params)
    end

    ##
    # An update expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def update(ref, params)
      Expr.new update: expr(ref), params: expr(params)
    end

    ##
    # A replace expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def replace(ref, params)
      Expr.new replace: expr(ref), params: expr(params)
    end

    ##
    # A delete expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def delete(ref)
      Expr.new delete: expr(ref)
    end

    ##
    # An insert expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def insert(ref, ts, action, params)
      Expr.new insert: expr(ref), ts: expr(ts), action: expr(action), params: expr(params)
    end

    ##
    # A remove expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def remove(ref, ts, action)
      Expr.new remove: expr(ref), ts: expr(ts), action: expr(action)
    end

    # :section: Sets

    ##
    # A match expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def match(index, *terms)
      Expr.new match: expr(index), terms: varargs(terms)
    end

    ##
    # A union expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def union(*sets)
      Expr.new union: varargs(sets)
    end

    ##
    # An intersection expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def intersection(*sets)
      Expr.new intersection: varargs(sets)
    end

    ##
    # A difference expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def difference(*sets)
      Expr.new difference: varargs(sets)
    end

    ##
    # A join expression
    #
    # Only one of `lam` or `blk` should be provided.
    # For example: <code>Fauna.query { join(source) { |x| match some_index, x } }</code>.
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def join(source, lam = nil, &blk)
      Expr.new join: expr(source), with: expr(lam || blk)
    end

    # :section: String Functions

    ##
    # A concat function
    #
    # Reference: {FaunaDB String Functions}[https://faunadb.com/documentation/queries#string_functions]
    def concat(strings, separator = nil)
      if separator.nil?
        Expr.new concat: expr(strings)
      else
        Expr.new concat: expr(strings), separator: expr(separator)
      end
    end

    ##
    # A casefold function
    #
    # Reference: {FaunaDB String Functions}[https://faunadb.com/documentation/queries#string_functions]
    def casefold(string)
      Expr.new casefold: expr(string)
    end

    # :section: Time and Date Functions

    ##
    # A time expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def time(string)
      Expr.new time: expr(string)
    end

    ##
    # An epoch expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def epoch(number, unit)
      Expr.new epoch: expr(number), unit: expr(unit)
    end

    ##
    # A date expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def date(string)
      Expr.new date: expr(string)
    end

    # :section: Miscellaneous Functions

    ##
    # An equals function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def equals(*values)
      Expr.new equals: varargs(values)
    end

    ##
    # A contains function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def contains(path, in_)
      Expr.new contains: expr(path), in: expr(in_)
    end

    ##
    # A select function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def select(path, from, params = {})
      Expr.new(expr_values(params).merge select: expr(path), from: expr(from))
    end

    ##
    # An add function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def add(*numbers)
      Expr.new add: varargs(numbers)
    end

    ##
    # A multiply function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def multiply(*numbers)
      Expr.new multiply: varargs(numbers)
    end

    ##
    # A subtract function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def subtract(*numbers)
      Expr.new subtract: varargs(numbers)
    end

    ##
    # A divide function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def divide(*numbers)
      Expr.new divide: varargs(numbers)
    end

    ##
    # A modulo function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def modulo(*numbers)
      Expr.new modulo: varargs(numbers)
    end

    ##
    # An and function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def and_(*booleans)
      Expr.new and: varargs(booleans)
    end

    ##
    # An or function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def or_(*booleans)
      Expr.new or: varargs(booleans)
    end

    ##
    # A not function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def not(boolean)
      Expr.new not: expr(boolean)
    end

  private

    # :nodoc:
    class Expr
      attr_reader :raw
      alias_method :to_hash, :raw

      def initialize(obj)
        @raw = obj
      end

      def to_json(*a)
        raw.to_json(*a)
      end
    end

    def expr(obj)
      if obj.is_a? Expr
        obj
      elsif obj.is_a? Proc
        self.lambda(&obj)
      elsif obj.is_a? Hash
        Expr.new object: expr_values(obj)
      elsif obj.is_a? Array
        Expr.new(obj.map { |v| expr(v) })
      else
        obj
      end
    end

    def expr_values(obj)
      obj.inject({}) { |h,(k,v)| h[k] = expr(v); h }
    end

    def block_parameters(block)
      block.parameters.map do |kind, name|
        fail ArgumentError, 'Splat parameters are not supported in lambda expressions.' if kind == :rest
        name
      end
    end

    ##
    # Called on splat arguments.
    #
    # This ensures that a single value passed is not put in an array, so
    # <code>query.add([1, 2])</code> will work as well as <code>query.add(1, 2)</code>.
    def varargs(values)
      expr(values.length == 1 ? values[0] : values)
    end
  end
end
