require 'response'

module Fauna
  class Query
    # Basic forms
    def self.let(vars, in_expr)
      { 'let' => vars, 'in' => in_expr }
    end

    def self.var(name)
      { 'var' => name }
    end

    def self.if(condition, true_expr, false_expr)
      { 'if' => condition, 'then' => true_expr, 'else' => false_expr }
    end

    def self.do(expressions)
      { 'do' => expressions }
    end

    def self.object(expr)
      { 'object' => expr }
    end

    def self.quote(expr)
      { 'quote' => expr }
    end

    def self.lambda(var, expr)
      { 'lambda' => var, 'expr' => expr }
    end

    # Collections
    def self.map(lambda_expr, coll)
      { 'map' => lambda_expr, 'collection' => coll }
    end

    def self.foreach(lambda_expr, coll)
      { 'foreach' => lambda_expr, 'collection' => coll }
    end

    # Read functions
    def self.get(ref, params = {})
      append_params({ 'get' => ref }, params, %w(ts))
    end

    def self.paginate(set, params = {})
      append_params({ 'paginate' => set }, params, %w(ts after before size events sources))
    end

    def self.exists(ref, params = {})
      append_params({ 'exists' => ref }, params, %w(ts))
    end

    def self.count(set, params = {})
      append_params({ 'count' => set }, params, %w(events))
    end

    # Write functions
    def self.create(class_ref, params)
      { 'create' => class_ref, 'params' => params }
    end

    def self.update(ref, params)
      { 'update' => ref, 'params' => params }
    end

    def self.replace(ref, params)
      { 'replace' => ref, 'params' => params }
    end

    def self.delete(ref)
      { 'delete' => ref }
    end

    # Sets
    def self.match(terms, index_ref)
      Set.new(terms, index_ref).to_hash
    end

    def self.union(sets)
      { 'union' => sets }
    end

    def self.intersection(sets)
      { 'intersection' => sets }
    end

    def self.difference(source, sets)
      { 'difference' => sets.unshift(source) }
    end

    def self.join(source, target)
      { 'join' => source, 'with' => target}
    end

    # Miscellaneous Functions
    def self.equals(values)
      { 'equals' => values }
    end

    def self.concat(strings)
      { 'concat' => strings }
    end

    def self.contains(path, value)
      { 'contains' => path, 'in' => value}
    end

    def self.select(path, data, params = {})
      append_params({ 'select' => path, 'from' => data }, params, %w(ts after before size events sources))
    end

    def self.add(numbers)
      { 'add' => numbers }
    end

    def self.multiply(numbers)
      { 'multiply' => numbers }
    end

    def self.subtract(numbers)
      { 'subtract' => numbers }
    end

    def self.divide(numbers)
      { 'divide' => numbers }
    end

    # Forms
    def self.event(ts, action, resource)
      Event.new(ts, action, resource).to_hash
    end

    private
    def self.append_params(source, params, allowed)
      source.merge(params.select { |key, value | allowed.include?(key) && !value.nil? })
    end
  end
end
