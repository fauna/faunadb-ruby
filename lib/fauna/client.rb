module Fauna
  ##
  # The Ruby client for FaunaDB.
  class Client
    # The Connection in use by the Client.
    attr_reader :connection

    ##
    # Create a new Client.
    #
    # +params+:: A list of parameters to configure the connection with.
    #            +:logger+:: A logger to output client traffic to.
    #                        Setting the +FAUNA_DEBUG+ environment variable will also log to +STDERR+.
    #            +:domain+:: The domain to send requests to.
    #            +:scheme+:: Scheme to use when sending requests (either +http+ or +https+).
    #            +:port+:: Port to use when sending requests.
    #            +:timeout+:: Read timeout in seconds.
    #            +:connection_timeout+:: \Connection open timeout in seconds.
    #            +:adapter+:: Faraday adapter to use. Either can be a symbol for the adapter, or an array of arguments.
    #            +:secret+:: Credentials to use when sending requests. User and pass must be separated by a colon.
    def initialize(params = {})
      @connection = Connection.new(params)
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
      parse(connection.get(path.to_s, query))
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
      parse(connection.post(path.to_s, data))
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
      parse(connection.put(path.to_s, data))
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
      parse(connection.patch(path.to_s, data))
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
      parse(connection.delete(path.to_s, data))
    end

    ##
    # Issues a query to FaunaDB.
    #
    # Queries are built via the Query helpers. See {FaunaDB Query API}[https://faunadb.com/documentation#queries]
    # for information on constructing queries.
    #
    # +expression+:: A query expression
    #
    # :category: Query Methods
    def query(expression)
      post('', expression)
    end

  private

    def deserialize(obj)
      if obj.is_a?(Hash)
        if obj.key? '@ref'
          Ref.new(obj['@ref'])
        elsif obj.key? '@set'
          Set.new(deserialize(obj['@set']))
        elsif obj.key? '@obj'
          deserialize(obj['@obj'])
        else
          Hash[obj.collect { |k, v| [k, deserialize(v)] }]
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
        body['resource']
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
