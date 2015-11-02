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
    def self.event(ts, action, resource)
      Event.new(ts, action, resource).to_hash
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
    def self.if(condition, true_expr, false_expr)
      { if: condition, then: true_expr, else: false_expr }
    end

    ##
    # A do expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.do(*expressions)
      varargs_query :do, expressions
    end

    ##
    # An object expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation/queries#basic_forms]
    def self.object(expr)
      { object: expr }
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
    #   query.lambda do |a|
    #     query.add(a, a)
    #   end
    #   # Produces: {lambda: 'auto0', expr: {add: [{var: 'auto0'}, {var: 'auto0'}]}}
    #
    # Query functions requiring lambdas can be passed blocks without explicitly calling ::lambda.
    #
    # You can also use ::lambda_expr and ::var directly.
    def self.lambda
      Thread.current[:fauna_lambda_var_number] ||= 0
      var_name = "auto#{Thread.current[:fauna_lambda_var_number]}"
      Thread.current[:fauna_lambda_var_number] += 1

      begin
        lambda_expr var_name, yield(var(var_name))
      ensure
        Thread.current[:fauna_lambda_var_number] -= 1
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
    def self.map(coll, lambda_expr = nil, &lambda_block)
      { map: lambda_expr || lambda(&lambda_block), collection: coll }
    end

    ##
    # A foreach expression
    #
    # Only one of \lambda_expr or lambda_block should be provided; prefer using blocks.
    # For example: <code>Fauna::Query.foreach(collection) { |a| Fauna::Query.delete a }</code>.
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation/queries#collection_functions]
    def self.foreach(coll, lambda_expr = nil, &lambda_block)
      { foreach: lambda_expr || lambda(&lambda_block), collection: coll }
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

    # :section: Sets

    ##
    # A match expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.match(terms, index_ref)
      { match: terms, index: index_ref }
    end

    ##
    # A union expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.union(*sets)
      varargs_query :union, sets
    end

    ##
    # An intersection expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.intersection(*sets)
      varargs_query :intersection, sets
    end

    ##
    # A difference expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation/queries#sets]
    def self.difference(*sets)
      varargs_query :difference, sets
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

    # :section: Miscellaneous Functions

    ##
    # An equals function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.equals(*values)
      varargs_query :equals, values
    end

    ##
    # A concat function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.concat(*strings)
      varargs_query :concat, strings
    end

    ##
    # A contains function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.contains(path, value)
      { contains: path, in: value }
    end

    ##
    # A select function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.select(path, data, params = {})
      { select: path, from: data }.merge(params)
    end

    ##
    # An add function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.add(*numbers)
      varargs_query :add, numbers
    end

    ##
    # A multiply function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.multiply(*numbers)
      varargs_query :multiply, numbers
    end

    ##
    # A subtract function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.subtract(*numbers)
      varargs_query :subtract, numbers
    end

    ##
    # A divide function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation/queries#misc_functions]
    def self.divide(*numbers)
      varargs_query :divide, numbers
    end

  private

    ##
    # Call name with varargs.
    #
    # This ensures that a single value passed is not put in array, so
    # <code>query.add(query.var(x))</code> will work where
    # <code>x</code> is a list whose values are to be added.
    def self.varargs_query(name, values)
      if values.length == 1
        { name => values[0] }
      else
        { name => values }
      end
    end
  end
end
