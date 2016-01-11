module Fauna
  ##
  # Helpers modeling the FaunaDB \Query language.
  #
  # Helpers can be composed to build a query expression, which can then be passed to Client.query
  # in order to execute the query.
  #
  # Example:
  #
  #   query = Fauna::Query.create(Fauna::Ref.new('classes', 'spells'), Fauna::Query.quote(data: { name: 'Magic Missile' }))
  module Query
    # :section: Values

    ##
    # An event
    #
    # Reference: {FaunaDB Values}[https://faunadb.com/documentation/queries#values]
    def self.event(resource, ts, action)
      Event.new(resource, ts, action).to_hash
    end

    # :section: Basic forms

    ##
    # A let expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.let(vars, in_expr)
      { let: vars, in: in_expr }
    end

    ##
    # Alternate form of ::let.
    #
    # Use like:
    #
    #   Query.let_query 1, 2 do |a, b|
    #     Query.add a, b
    #   end
    #
    # +values+:: Values to be assigned to generated variables, which are passed into the block.
    def self.let_query(*values)
      n_args = values.length

      with_auto_vars(n_args) do |vars|
        dct = {}
        (0...n_args).each do |i|
          dct[vars[i]] = values[i]
        end
        let dct, yield(*(vars.map { |v| var(v) }))
      end
    end

    ##
    # A var expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.var(name)
      { var: name }
    end

    ##
    # An if expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.if(condition, then_, else_)
      { if: condition, then: then_, else: else_ }
    end

    ##
    # A do expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.do(*expressions)
      { do: varargs(expressions) }
    end

    ##
    # An object expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.object(fields)
      { object: fields }
    end

    ##
    # A quote expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.quote(expr)
      { quote: expr }
    end

    ##
    # A lambda expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    #
    # This form generates the names of lambda parameters for you, and is called like:
    #
    #   Query.lambda do |a|
    #     Query.add(a, a)
    #   end
    #   # Produces: {lambda: 'auto0', expr: {add: [{var: 'auto0'}, {var: 'auto0'}]}}
    #
    # Query functions requiring lambdas can be passed blocks without explicitly calling ::lambda.
    #
    # You can also use ::lambda_expr and ::var directly.
    # +block+::
    #   Takes one or more ::var expressions and uses them to construct an expression.
    #   If this takes more than one argument, the lambda destructures an array argument.
    #   (To destructure single-element arrays use ::lambda_expr.)
    def self.lambda(&block)
      n_args = block.arity
      fail ArgumentError, 'Function must take at least 1 argument.' if n_args == 0

      with_auto_vars(n_args) do |vars|
        if n_args == 1
          lambda_expr vars[0], block.call(var(vars[0]))
        else
          lambda_expr vars, block.call(*(vars.map { |v| var(v) }))
        end
      end
    end

    ##
    # A raw lambda expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    #
    # See also ::lambda.
    def self.lambda_expr(var, expr)
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
    def self.map(collection, lambda_expr = nil, &lambda_block)
      { map: lambda_expr || lambda(&lambda_block), collection: collection }
    end

    ##
    # A foreach expression
    #
    # Only one of \lambda_expr or lambda_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.foreach(collection) { |a| Fauna::Query.delete a }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def self.foreach(collection, lambda_expr = nil, &lambda_block)
      { foreach: lambda_expr || lambda(&lambda_block), collection: collection }
    end

    ##
    # A filter expression
    #
    # Only one of \lambda_expr or lambda_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.filter(collection) { |a| Fauna::Query.equals a, 1 }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def self.filter(collection, lambda_expr = nil, &lambda_block)
      { filter: lambda_expr || lambda(&lambda_block), collection: collection }
    end

    ##
    # A take expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def self.take(number, collection)
      { take: number, collection: collection }
    end

    ##
    # A drop expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def self.drop(number, collection)
      { drop: number, collection: collection }
    end

    ##
    # A prepend expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def self.prepend(elements, collection)
      { prepend: elements, collection: collection }
    end

    ##
    # An append expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def self.append(elements, collection)
      { append: elements, collection: collection }
    end

    # :section: Read functions

    ##
    # A get expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def self.get(ref, params = {})
      { get: ref }.merge(params)
    end

    ##
    # A paginate expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def self.paginate(set, params = {})
      { paginate: set }.merge(params)
    end

    ##
    # An exists expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def self.exists(ref, params = {})
      { exists: ref }.merge(params)
    end

    ##
    # A count expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation/queries#read_functions]
    def self.count(set, params = {})
      { count: set }.merge(params)
    end

    # :section: Write functions

    ##
    # A create expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def self.create(class_ref, params)
      { create: class_ref, params: params }
    end

    ##
    # An update expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def self.update(ref, params)
      { update: ref, params: params }
    end

    ##
    # A replace expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def self.replace(ref, params)
      { replace: ref, params: params }
    end

    ##
    # A delete expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def self.delete(ref)
      { delete: ref }
    end

    ##
    # An insert expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def self.insert(ref, ts, action, params)
      { insert: ref, ts: ts, action: action, params: params }
    end

    # +insert+ that takes an +Event+ object instead of separate parameters.
    def self.insert_event(event, params)
      insert(event.resource, event.ts, event.action, params)
    end

    ##
    # A remove expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation/queries#write_functions]
    def self.remove(ref, ts, action)
      { remove: ref, ts: ts, action: action }
    end

    # +remove+ that takes an +Event+ object instead of separate parameters.
    def self.remove_event(event)
      remove(event.resource, event.ts, event.action)
    end

    # :section: Sets

    ##
    # A match expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.match(terms, index)
      { match: index, terms: terms }
    end

    ##
    # A union expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.union(*sets)
      { union: varargs(sets) }
    end

    ##
    # An intersection expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.intersection(*sets)
      { intersection: varargs(sets) }
    end

    ##
    # A difference expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.difference(*sets)
      { difference: varargs(sets) }
    end

    ##
    # A join expression
    #
    # Only one of target_expr or target_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.join(source) { |x| Fauna::Query.match x, some_index }</code>.
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.join(source, target_expr = nil, &target_block)
      { join: source, with: target_expr || lambda(&target_block) }
    end

    # :section: String Functions

    ##
    # A concat function
    #
    # Reference: {FaunaDB String Functions}[https://faunadb.com/documentation/queries#string_functions]
    def self.concat(strings, separator = nil)
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
    def self.casefold(string)
      { casefold: string }
    end

    # :section: Time and Date Functions

    ##
    # A time expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def self.time(string)
      { time: string }
    end

    ##
    # An epoch expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def self.epoch(number, unit)
      { epoch: number, unit: unit }
    end

    ##
    # A date expression
    #
    # Reference: {FaunaDB Time Functions}[https://faunadb.com/documentation/queries#time_functions]
    def self.date(string)
      { date: string }
    end

    # :section: Miscellaneous Functions

    ##
    # An equals function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.equals(*values)
      { equals: varargs(values) }
    end

    ##
    # A contains function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.contains(path, in_)
      { contains: path, in: in_ }
    end

    ##
    # A select function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.select(path, from, params = {})
      { select: path, from: from }.merge(params)
    end

    ##
    # An add function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.add(*numbers)
      { add: varargs(numbers) }
    end

    ##
    # A multiply function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.multiply(*numbers)
      { multiply: varargs(numbers) }
    end

    ##
    # A subtract function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.subtract(*numbers)
      { subtract: varargs(numbers) }
    end

    ##
    # A divide function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.divide(*numbers)
      { divide: varargs(numbers) }
    end

    ##
    # A modulo function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.modulo(*numbers)
      { modulo: varargs(numbers) }
    end

    ##
    # An and function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.and(*booleans)
      { and: varargs(booleans) }
    end

    ##
    # An or function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.or(*booleans)
      { or: varargs(booleans) }
    end

    ##
    # A not function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.not(boolean)
      { not: boolean }
    end

  private

    def self.with_auto_vars(n_vars)
      low_var_number = Thread.current[:fauna_lambda_var_number] || 0
      next_var_number = low_var_number + n_vars

      Thread.current[:fauna_lambda_var_number] = next_var_number

      yield (low_var_number...next_var_number).map { |i| "auto#{i}" }
    ensure
      Thread.current[:fauna_lambda_var_number] = low_var_number
    end

    ##
    # Called on splat arguments.
    #
    # This ensures that a single value passed is not put in an array, so
    # <code>query.add([1, 2])</code> will work as well as <code>query.add(1, 2)</code>.
    def self.varargs(values)
      values.length == 1 ? values[0] : values
    end
  end
end
