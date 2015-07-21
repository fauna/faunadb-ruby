module Fauna
  ##
  # The Ruby client for FaunaDB.
  class Client
    # The Connection in use by the Client.
    attr_reader :connection

    ##
    # Create a new Client from a Connection.
    #
    # +connection+:: Connection for the Client to use.
    def initialize(connection)
      @connection = connection
    end

    ##
    # Performs a GET request for a REST endpoint.
    #
    # +path+:: Path to GET.
    # +query+:: Query parameters to append to the path.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation#rest]
    #
    # :category: REST Methods
    def get(path, query = {})
      parse(connection.get(path, query))
    end

    ##
    # Performs a POST request for a REST endpoint.
    #
    # +path+:: Path to POST.
    # +data+:: Data to post as the body.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation#rest]
    #
    # :category: REST Methods
    def post(path, data = {})
      parse(connection.post(path, data))
    end

    ##
    # Performs a PUT request for a REST endpoint.
    #
    # +path+:: Path to PUT.
    # +data+:: Data to post as the body.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation#rest]
    #
    # :category: REST Methods
    def put(path, data = {})
      parse(connection.put(path, data))
    end

    ##
    # Performs a PATCH request for a REST endpoint.
    #
    # +path+:: Path to PATCH.
    # +data+:: Data to post as the body.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation#rest]
    #
    # :category: REST Methods
    def patch(path, data = {})
      parse(connection.patch(path, data))
    end

    ##
    # Performs a DELETE request for a REST endpoint.
    #
    # +path+:: Path to DELETE.
    # +data+:: Data to post as the body.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation#rest]
    #
    # :category: REST Methods
    def delete(path, data = {})
      parse(connection.delete(path, data))
    end

    ##
    # Issues a query to FaunaDB
    #
    # Queries are built via the Query helpers. See {FaunaDB Query API}[https://faunadb.com/documentation#queries]
    # for information on constructing queries.
    #
    # +expression+:: A query expression
    #
    # :category: Query Methods
    def query(expression) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      methods = %w(get create update replace delete)
      classes = %w(databases keys)

      methods.each do |method|
        ref = expression[method]
        next unless ref

        fauna_class = ref.to_class.ref
        next unless classes.include?(fauna_class)

        ref = ref.ref
        case method
        when 'get'
          return get(ref, ts: expression['ts'])
        when 'create'
          fail InvalidQuery("#{fauna_class} does not support object, use quote") unless expression['params']['object'].nil?
          return post(ref, expression['params']['quote'])
        when 'update'
          fail InvalidQuery("#{fauna_class} does not support object, use quote") unless expression['params']['object'].nil?
          return patch(ref, expression['params']['quote'])
        when 'replace'
          fail InvalidQuery("#{fauna_class} does not support object, use quote") unless expression['params']['object'].nil?
          return put(ref, expression['params']['quote'])
        when 'delete'
          return delete(ref)
        end
      end

      post('', expression)
    end

    ##
    # Yields a client with the given connection.
    #
    # +connection+:: Connection for the Client to use.
    #
    # Example:
    #
    #   Client.context(connection) do |client|
    #     client.get('/ping')
    #   end
    def self.context(connection)
      yield Client.new(connection)
    end

  private

    def deserialize(obj)
      if obj.is_a?(Hash)
        if obj.key? '@ref'
          Ref.new(obj['@ref'])
        elsif obj.key? '@set'
          Set.new(obj['@set']['match'], obj['@set']['match'])
        elsif obj.key? '@obj'
          Obj.new.merge(obj['@obj'])
        else
          obj.update(obj) { |_, v| deserialize(v) }
        end
      else
        obj
      end
    end

    def parse(response) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      if response.body.empty?
        body = nil
      else
        body = deserialize(response.body)
      end
      error_body = body || "Status #{response.status}"

      case response.status
      when 200..299
        body
      when 400
        fail BadRequest.new(error_body)
      when 401
        fail Unauthorized.new(error_body)
      when 403
        fail PermissionDenied.new(error_body)
      when 404
        fail NotFound.new(error_body)
      when 405
        fail MethodNotAllowed.new(error_body)
      when 500
        fail InternalError.new(error_body)
      when 503
        fail UnavailableError.new(error_body)
      else
        fail FaunaError.new(error_body)
      end
    end
  end
end
