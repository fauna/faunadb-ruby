module Fauna
  ##
  # Helpers modeling the FaunaDB \Query language.
  #
  # Helpers can be composed to build a query expression, which can then be passed to Client.query
  # in order to execute the query.
  #
  # Example:
  #
  #   query = Fauna::Query.create(Fauna::Ref('classes/spells'), Fauna::Query.quote('data' => {'name' => 'Magic Missile'}))
  module Query
    # :section: Values

    # An event
    #
    # Reference: {FaunaDB Values}[https://faunadb.com/documentation#queries-values]
    def self.event(ts, action, resource)
      Event.new(ts, action, resource).to_hash
    end

    # :section: Basic forms

    # A let expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation#queries-basic_forms]
    def self.let(vars, in_expr)
      { 'let' => vars, 'in' => in_expr }
    end

    # A var expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation#queries-basic_forms]
    def self.var(name)
      { 'var' => name }
    end

    # An if expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation#queries-basic_forms]
    def self.if(condition, true_expr, false_expr)
      { 'if' => condition, 'then' => true_expr, 'else' => false_expr }
    end

    # A do expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation#queries-basic_forms]
    def self.do(expressions)
      { 'do' => expressions }
    end

    # An object expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation#queries-basic_forms]
    def self.object(expr)
      { 'object' => expr }
    end

    # A quote expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation#queries-basic_forms]
    def self.quote(expr)
      { 'quote' => expr }
    end

    # A lambda expression
    #
    # Reference: {FaunaDB Basic Forms}[https://faunadb.com/documentation#queries-basic_forms]
    def self.lambda(var, expr)
      { 'lambda' => var, 'expr' => expr }
    end

    # :section: Collections

    # A map expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation#queries-collection_functions]
    def self.map(lambda_expr, coll)
      { 'map' => lambda_expr, 'collection' => coll }
    end

    # A foreach expression
    #
    # Reference: {FaunaDB Collections}[https://faunadb.com/documentation#queries-collection_functions]
    def self.foreach(lambda_expr, coll)
      { 'foreach' => lambda_expr, 'collection' => coll }
    end

    # :section: Read functions

    # A get expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation#queries-read_functions]
    def self.get(ref, params = {})
      append_params({ 'get' => ref }, params, %w(ts))
    end

    # A paginate expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation#queries-read_functions]
    def self.paginate(set, params = {})
      append_params({ 'paginate' => set }, params, %w(ts after before size events sources))
    end

    # An exists expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation#queries-read_functions]
    def self.exists(ref, params = {})
      append_params({ 'exists' => ref }, params, %w(ts))
    end

    # A count expression
    #
    # Reference: {FaunaDB Read functions}[https://faunadb.com/documentation#queries-read_functions]
    def self.count(set, params = {})
      append_params({ 'count' => set }, params, %w(events))
    end

    # :section: Write functions

    # A create expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation#queries-write_functions]
    def self.create(class_ref, params)
      { 'create' => class_ref, 'params' => params }
    end

    # An update expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation#queries-write_functions]
    def self.update(ref, params)
      { 'update' => ref, 'params' => params }
    end

    # A replace expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation#queries-write_functions]
    def self.replace(ref, params)
      { 'replace' => ref, 'params' => params }
    end

    # A delete expression
    #
    # Reference: {FaunaDB Write functions}[https://faunadb.com/documentation#queries-write_functions]
    def self.delete(ref)
      { 'delete' => ref }
    end

    # :section: Sets

    # A match expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation#queries-sets]
    def self.match(terms, index_ref)
      Set.new(terms, index_ref).to_hash
    end

    # A union expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation#queries-sets]
    def self.union(sets)
      { 'union' => sets }
    end

    # An intersection expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation#queries-sets]
    def self.intersection(sets)
      { 'intersection' => sets }
    end

    # A difference expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation#queries-sets]
    def self.difference(source, sets)
      { 'difference' => sets.unshift(source) }
    end

    # A join expression
    #
    # Reference: {FaunaDB Sets}[https://faunadb.com/documentation#queries-sets]
    def self.join(source, target)
      { 'join' => source, 'with' => target }
    end

    # :section: Miscellaneous Functions

    # An equals function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.equals(values)
      { 'equals' => values }
    end

    # A concat function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.concat(strings)
      { 'concat' => strings }
    end

    # A contains function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.contains(path, value)
      { 'contains' => path, 'in' => value }
    end

    # A select function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.select(path, data, params = {})
      append_params({ 'select' => path, 'from' => data }, params, %w(ts after before size events sources))
    end

    # An add function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.add(numbers)
      { 'add' => numbers }
    end

    # A multiply function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.multiply(numbers)
      { 'multiply' => numbers }
    end

    # A subtract function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.subtract(numbers)
      { 'subtract' => numbers }
    end

    # A divide function
    #
    # Reference: {FaunaDB Miscellaneous Functions}[https://faunadb.com/documentation#queries-misc_functions]
    def self.divide(numbers)
      { 'divide' => numbers }
    end

  private

    def self.append_params(source, params, allowed)
      source.merge(params.select { |key, value | allowed.include?(key) && !value.nil? })
    end
  end
end
