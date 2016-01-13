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

    DSLContext.eval_dsl(dsl, &block)
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
    # An event
    #
    # Reference: {FaunaDB Values}[https://faunadb.com/documentation/queries#values]
    def event(resource, ts, action)
      Event.new(resource, ts, action).to_hash
    end

    # :section: Basic forms

    ##
    # A let expression
    #
    # Example: <code>Fauna.query { let(x: 2).in(add(1, var(:x))) }</code>.
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

      { let: vars, in: in_ }
    end

    ##
    # A var expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def var(name)
      { var: name }
    end

    ##
    # An if expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def if_(condition, then_, else_)
      { if: condition, then: then_, else: else_ }
    end

    ##
    # A do expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def do_(*expressions)
      { do: varargs(expressions) }
    end

    ##
    # An object expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def object(fields)
      { object: fields }
    end

    ##
    # A quote expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def quote(expr)
      { quote: expr }
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
      { lambda: var, expr: expr }
    end

    # :section: Collections

    ##
    # A map expression
    #
    # Only one of \lambda_expr or lambda_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.map(collection) { |a| Fauna::Query.add a, 1 }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def map(collection, lambda_expr = nil, &lambda_block)
      { map: lambda_expr || lambda(&lambda_block), collection: collection }
    end

    ##
    # A foreach expression
    #
    # Only one of \lambda_expr or lambda_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.foreach(collection) { |a| Fauna::Query.delete a }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def foreach(collection, lambda_expr = nil, &lambda_block)
      { foreach: lambda_expr || lambda(&lambda_block), collection: collection }
    end

    ##
    # A filter expression
    #
    # Only one of \lambda_expr or lambda_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.filter(collection) { |a| Fauna::Query.equals a, 1 }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def filter(collection, lambda_expr = nil, &lambda_block)
      { filter: lambda_expr || lambda(&lambda_block), collection: collection }
    end

    ##
    # A take expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def take(number, collection)
      { take: number, collection: collection }
    end

    ##
    # A drop expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def drop(number, collection)
      { drop: number, collection: collection }
    end

    ##
    # A prepend expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def prepend(elements, collection)
      { prepend: elements, collection: collection }
    end

    ##
    # An append expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def append(elements, collection)
      { append: elements, collection: collection }
    end

    # :section: Read functions

    ##
    # A get expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def get(ref, params = {})
      { get: ref }.merge(params)
    end

    ##
    # A paginate expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def paginate(set, params = {})
      { paginate: set }.merge(params)
    end

    ##
    # An exists expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def exists(ref, params = {})
      { exists: ref }.merge(params)
    end

    ##
    # A count expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def count(set, params = {})
      { count: set }.merge(params)
    end

    # :section: Write functions

    ##
    # A create expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def create(class_ref, params)
      { create: class_ref, params: params }
    end

    ##
    # An update expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def update(ref, params)
      { update: ref, params: params }
    end

    ##
    # A replace expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def replace(ref, params)
      { replace: ref, params: params }
    end

    ##
    # A delete expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def delete(ref)
      { delete: ref }
    end

    ##
    # An insert expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def insert(ref, ts, action, params)
      { insert: ref, ts: ts, action: action, params: params }
    end

    # +insert+ that takes an +Event+ object instead of separate parameters.
    def insert_event(event, params)
      insert(event.resource, event.ts, event.action, params)
    end

    ##
    # A remove expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def remove(ref, ts, action)
      { remove: ref, ts: ts, action: action }
    end

    # +remove+ that takes an +Event+ object instead of separate parameters.
    def remove_event(event)
      remove(event.resource, event.ts, event.action)
    end

    # :section: Sets

    ##
    # A match expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def match(index, *terms)
      { match: index, terms: varargs(terms) }
    end

    ##
    # A union expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def union(*sets)
      { union: varargs(sets) }
    end

    ##
    # An intersection expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def intersection(*sets)
      { intersection: varargs(sets) }
    end

    ##
    # A difference expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def difference(*sets)
      { difference: varargs(sets) }
    end

    ##
    # A join expression
    #
    # Only one of target_expr or target_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.join(source) { |x| Fauna::Query.match x, some_index }</code>.
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def join(source, target_expr = nil, &target_block)
      { join: source, with: target_expr || lambda(&target_block) }
    end

    # :section: String Functions

    ##
    # A concat function
    #
    # Reference: {FaunaDB String Functions}[https://faunadb.com/documentation/queries#string_functions]
    def concat(strings, separator = nil)
      if separator.nil?
        { concat: strings }
      else
        { concat: strings, separator: separator }
      end
    end

    ##
    # A casefold function
    #
    # Reference: {FaunaDB String Functions}[https://faunadb.com/documentation/queries#string_functions]
    def casefold(string)
      { casefold: string }
    end

    # :section: Time and Date Functions

    ##
    # A time expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def time(string)
      { time: string }
    end

    ##
    # An epoch expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def epoch(number, unit)
      { epoch: number, unit: unit }
    end

    ##
    # A date expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def date(string)
      { date: string }
    end

    # :section: Miscellaneous Functions

    ##
    # An equals function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def equals(*values)
      { equals: varargs(values) }
    end

    ##
    # A contains function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def contains(path, in_)
      { contains: path, in: in_ }
    end

    ##
    # A select function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def select(path, from, params = {})
      { select: path, from: from }.merge(params)
    end

    ##
    # An add function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def add(*numbers)
      { add: varargs(numbers) }
    end

    ##
    # A multiply function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def multiply(*numbers)
      { multiply: varargs(numbers) }
    end

    ##
    # A subtract function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def subtract(*numbers)
      { subtract: varargs(numbers) }
    end

    ##
    # A divide function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def divide(*numbers)
      { divide: varargs(numbers) }
    end

    ##
    # A modulo function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def modulo(*numbers)
      { modulo: varargs(numbers) }
    end

    ##
    # An and function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def and_(*booleans)
      { and: varargs(booleans) }
    end

    ##
    # An or function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def or_(*booleans)
      { or: varargs(booleans) }
    end

    ##
    # A not function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def not_(boolean)
      { not: boolean }
    end

  private

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
      values.length == 1 ? values[0] : values
    end
  end
end
