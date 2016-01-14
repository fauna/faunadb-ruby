module Fauna
  ##
  # Helpers modeling the FaunaDB \Query language.
  #
  # Helpers are usually used via a concise DSL notation. A DSL block
  # may be used directly with Fauna::Client:
  #
  #   client.query { create(ref('classes', 'spells'), { data: { name: 'Magic Missile' } }) }
  #
  # To build and return an query expression to execute later, use Fauna::Query.expr:
  #
  #   Fauna::Query.expr { create(ref('classes', 'spells'), { data: { name: 'Magic Missile' } }) }
  #
  # Or, you may directly use the helper methods:
  #
  #   Fauna::Query.create(Fauna::Query.ref('classes', 'spells'), { data: { name: 'Magic Missile' } })
  module Query
    extend self

    # :nodoc:
    class QueryDSLContext < DSLContext
      include Query
    end

    ##
    # Build a query expression.
    #
    # Allows for unscoped calls to Fauna::Query methods within the
    # provided block. The block should return the constructed query
    # expression.
    #
    # Example: <code>Fauna::Query.expr { add(1, 2, subtract(3, 2)) }</code>
    def self.expr(&block)
      return nil if block.nil?

      dsl = QueryDSLContext.new

      Expr.wrap DSLContext.eval_dsl(dsl, &block)
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
    #   Fauna.query { { x: 1, y: add(1, 2) } }
    #   Fauna.query { object(x: 1, y: add(1, 2)) }
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def object(fields)
      Expr.new object: Expr.wrap_values(fields)
    end

    # :section: Basic forms

    ##
    # A let expression
    #
    # Only one of `expr` or `block` should be provided.
    #
    # Block example: <code>Fauna.query { let(x: 2) { add(1, x) } }</code>.
    #
    # Expression example: <code>Fauna.query { let({ x: 2 }, add(1, var(:x))) }</code>.
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def let(vars, expr = nil, &block)
      in_ =
        if block.nil?
          expr
        else
          dsl = QueryDSLContext.new
          dslcls = (class << dsl; self; end)

          vars.keys.each do |v|
            dslcls.send(:define_method, v) { var(v) }
          end

          DSLContext.eval_dsl(dsl, &block)
        end

      Expr.new let: Expr.wrap_values(vars), in: Expr.wrap(in_)
    end

    ##
    # A var expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def var(name)
      Expr.new var: Expr.wrap(name)
    end

    ##
    # An if expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def if_(condition, then_, else_)
      Expr.new if: Expr.wrap(condition), then: Expr.wrap(then_), else: Expr.wrap(else_)
    end

    ##
    # A do expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def do_(*expressions)
      Expr.new do: Expr.wrap_varargs(expressions)
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
      vars =
        block.parameters.map do |kind, name|
          fail ArgumentError, 'Splat parameters are not supported in lambda expressions.' if kind == :rest
          name
        end

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
      Expr.new lambda: Expr.wrap(var), expr: Expr.wrap(expr)
    end

    # :section: Collections

    ##
    # A map expression
    #
    # Only one of `lambda_expr` or `lambda_block` should be provided.
    # For example: <code>Fauna.query { map(collection) { |a| add a, 1 } }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def map(collection, lambda_expr = nil, &lambda_block)
      Expr.new map: Expr.wrap(lambda_expr || lambda_block), collection: Expr.wrap(collection)
    end

    ##
    # A foreach expression
    #
    # Only one of `lambda_expr` or `lambda_block` should be provided.
    # For example: <code>Fauna.query { foreach(collection) { |a| delete a } }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def foreach(collection, lambda_expr = nil, &lambda_block)
      Expr.new foreach: Expr.wrap(lambda_expr || lambda_block), collection: Expr.wrap(collection)
    end

    ##
    # A filter expression
    #
    # Only one of `lambda_expr` or `lambda_block` should be provided.
    # For example: <code>Fauna.query { filter(collection) { |a| equals a, 1 } }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def filter(collection, lambda_expr = nil, &lambda_block)
      Expr.new filter: Expr.wrap(lambda_expr || lambda_block), collection: Expr.wrap(collection)
    end

    ##
    # A take expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def take(number, collection)
      Expr.new take: Expr.wrap(number), collection: Expr.wrap(collection)
    end

    ##
    # A drop expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def drop(number, collection)
      Expr.new drop: Expr.wrap(number), collection: Expr.wrap(collection)
    end

    ##
    # A prepend expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def prepend(elements, collection)
      Expr.new prepend: Expr.wrap(elements), collection: Expr.wrap(collection)
    end

    ##
    # An append expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def append(elements, collection)
      Expr.new append: Expr.wrap(elements), collection: Expr.wrap(collection)
    end

    # :section: Read functions

    ##
    # A get expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def get(ref, params = {})
      Expr.new Expr.wrap_values(params).merge(get: Expr.wrap(ref))
    end

    ##
    # A paginate expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def paginate(set, params = {})
      Expr.new Expr.wrap_values(params).merge(paginate: Expr.wrap(set))
    end

    ##
    # An exists expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def exists(ref, params = {})
      Expr.new Expr.wrap_values(params).merge(exists: Expr.wrap(ref))
    end

    ##
    # A count expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def count(set, params = {})
      Expr.new Expr.wrap_values(params).merge(count: Expr.wrap(set))
    end

    # :section: Write functions

    ##
    # A create expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def create(class_ref, params)
      Expr.new create: Expr.wrap(class_ref), params: Expr.wrap(params)
    end

    ##
    # An update expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def update(ref, params)
      Expr.new update: Expr.wrap(ref), params: Expr.wrap(params)
    end

    ##
    # A replace expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def replace(ref, params)
      Expr.new replace: Expr.wrap(ref), params: Expr.wrap(params)
    end

    ##
    # A delete expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def delete(ref)
      Expr.new delete: Expr.wrap(ref)
    end

    ##
    # An insert expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def insert(ref, ts, action, params)
      Expr.new insert: Expr.wrap(ref), ts: Expr.wrap(ts), action: Expr.wrap(action), params: Expr.wrap(params)
    end

    ##
    # A remove expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def remove(ref, ts, action)
      Expr.new remove: Expr.wrap(ref), ts: Expr.wrap(ts), action: Expr.wrap(action)
    end

    # :section: Sets

    ##
    # A match expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def match(index, *terms)
      Expr.new match: Expr.wrap(index), terms: Expr.wrap_varargs(terms)
    end

    ##
    # A union expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def union(*sets)
      Expr.new union: Expr.wrap_varargs(sets)
    end

    ##
    # An intersection expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def intersection(*sets)
      Expr.new intersection: Expr.wrap_varargs(sets)
    end

    ##
    # A difference expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def difference(*sets)
      Expr.new difference: Expr.wrap_varargs(sets)
    end

    ##
    # A join expression
    #
    # Only one of `target_expr` or `target_block` should be provided.
    # For example: <code>Fauna.query { join(source) { |x| match some_index, x } }</code>.
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def join(source, target_expr = nil, &target_block)
      Expr.new join: Expr.wrap(source), with: Expr.wrap(target_expr || target_block)
    end

    # :section: Authentication

    ##
    # A login function
    #
    # Reference: {FaunaDB Authentication Functions}[https://faunadb.com/documentation/queries#auth_functions]
    def self.login(ref, params)
      { login: ref, params: params }
    end

    ##
    # Login with just a password
    #
    # Reference: {FaunaDB Authentication Functions}[https://faunadb.com/documentation/queries#auth_functions]
    def self.login_with_password(ref, password)
      login ref, object(password: password)
    end

    ##
    # A logout function
    #
    # Reference: {FaunaDB Authentication Functions}[https://faunadb.com/documentation/queries#auth_functions]
    def self.logout(delete_tokens)
      { logout: delete_tokens }
    end

    ##
    # An identify function
    #
    # Reference: {FaunaDB Authentication Functions}[https://faunadb.com/documentation/queries#auth_functions]
    def self.identify(ref, password)
      { identify: ref, password: password }
    end

    # :section: String Functions

    ##
    # A concat function
    #
    # Reference: {FaunaDB String Functions}[https://faunadb.com/documentation/queries#string_functions]
    def concat(strings, separator = nil)
      if separator.nil?
        Expr.new concat: Expr.wrap(strings)
      else
        Expr.new concat: Expr.wrap(strings), separator: Expr.wrap(separator)
      end
    end

    ##
    # A casefold function
    #
    # Reference: {FaunaDB String Functions}[https://faunadb.com/documentation/queries#string_functions]
    def casefold(string)
      Expr.new casefold: Expr.wrap(string)
    end

    # :section: Time and Date Functions

    ##
    # A time expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def time(string)
      Expr.new time: Expr.wrap(string)
    end

    ##
    # An epoch expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def epoch(number, unit)
      Expr.new epoch: Expr.wrap(number), unit: Expr.wrap(unit)
    end

    ##
    # A date expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def date(string)
      Expr.new date: Expr.wrap(string)
    end

    # :section: Miscellaneous Functions

    ##
    # An equals function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def equals(*values)
      Expr.new equals: Expr.wrap_varargs(values)
    end

    ##
    # A contains function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def contains(path, in_)
      Expr.new contains: Expr.wrap(path), in: Expr.wrap(in_)
    end

    ##
    # A select function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def select(path, from, params = {})
      Expr.new Expr.wrap_values(params).merge(select: Expr.wrap(path), from: Expr.wrap(from))
    end

    ##
    # An add function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def add(*numbers)
      Expr.new add: Expr.wrap_varargs(numbers)
    end

    ##
    # A multiply function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def multiply(*numbers)
      Expr.new multiply: Expr.wrap_varargs(numbers)
    end

    ##
    # A subtract function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def subtract(*numbers)
      Expr.new subtract: Expr.wrap_varargs(numbers)
    end

    ##
    # A divide function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def divide(*numbers)
      Expr.new divide: Expr.wrap_varargs(numbers)
    end

    ##
    # A modulo function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def modulo(*numbers)
      Expr.new modulo: Expr.wrap_varargs(numbers)
    end

    ##
    # An and function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def and_(*booleans)
      Expr.new and: Expr.wrap_varargs(booleans)
    end

    ##
    # An or function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def or_(*booleans)
      Expr.new or: Expr.wrap_varargs(booleans)
    end

    ##
    # A not function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def not_(boolean)
      Expr.new not: Expr.wrap(boolean)
    end

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

      def self.wrap(obj)
        if obj.is_a? Expr
          obj
        elsif obj.is_a? Proc
          Query.lambda(&obj)
        elsif obj.is_a? Hash
          Expr.new object: wrap_values(obj)
        elsif obj.is_a? Array
          Expr.new obj.map { |v| wrap(v) }
        else
          obj
        end
      end

      def self.wrap_values(obj)
        obj.inject({}) { |h, (k, v)| h[k] = wrap(v); h }
      end

      def self.wrap_varargs(values)
        wrap(values.length == 1 ? values[0] : values)
      end
    end
  end
end
