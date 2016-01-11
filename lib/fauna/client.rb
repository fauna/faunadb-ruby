module Fauna
  ##
  # The Ruby client for FaunaDB.
  #
  # All methods return a converted JSON response.
  # This is a Hash containing Arrays, ints, floats, strings, and other Hashes.
  # Hash keys are always Symbols.
  #
  # Any Ref, Set, Time or Date values in it will also be parsed.
  # (So instead of <code>{ "@ref": "classes/frogs/123" }</code>,
  # you will get <code>Fauna::Ref.new("classes/frogs/123")</code>).
  #
  # There is no way to automatically convert to any other type, such as Event,
  # from the response; you'll have to do that yourself manually.
  class Client
    # The Connection in use by the Client.
    attr_reader :connection

    ##
    # Create a new Client.
    #
    # +params+:: A list of parameters to configure the connection with.
    #            +:observer+:: Callback that will be passed a +RequestResult+ after every completed request.
    #            +:domain+:: The domain to send requests to.
    #            +:scheme+:: Scheme to use when sending requests (either +http+ or +https+).
    #            +:port+:: Port to use when sending requests.
    #            +:timeout+:: Read timeout in seconds.
    #            +:connection_timeout+:: Open timeout in seconds.
    #            +:adapter+:: Faraday[https://github.com/lostisland/faraday] adapter to use. Either can be a symbol for the adapter, or an array of arguments.
    #            +:secret+:: Credentials to use when sending requests. User and pass must be separated by a colon.
    def initialize(params = {})
      @connection = Connection.new(self, params)
    end

    ##
    # Performs a +GET+ request for a REST endpoint.
    #
    # +path+:: Path to GET.
    # +query+:: Query parameters to append to the path.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation/rest]
    #
    # :category: REST Methods
    def get(path, query = {})
      connection.get(path.to_s, query)
    end

    ##
    # Performs a +POST+ request for a REST endpoint.
    #
    # +path+:: Path to POST.
    # +data+:: Data to post as the body. +data+ is automatically converted to JSON.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation/rest]
    #
    # :category: REST Methods
    def post(path, data = {})
      connection.post(path.to_s, data)
    end

    ##
    # Performs a +PUT+ request for a REST endpoint.
    #
    # +path+:: Path to PUT.
    # +data+:: Data to post as the body. +data+ is automatically converted to JSON.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation/rest]
    #
    # :category: REST Methods
    def put(path, data = {})
      connection.put(path.to_s, data)
    end

    ##
    # Performs a +PATCH+ request for a REST endpoint.
    #
    # +path+:: Path to PATCH.
    # +data+:: Data to post as the body. +data+ is automatically converted to JSON.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation/rest]
    #
    # :category: REST Methods
    def patch(path, data = {})
      connection.patch(path.to_s, data)
    end

    ##
    # Performs a +DELETE+ request for a REST endpoint.
    #
    # +path+:: Path to DELETE.
    # +data+:: Data to post as the body. +data+ is automatically converted to JSON.
    #
    # Reference: {FaunaDB REST API}[https://faunadb.com/documentation/rest]
    #
    # :category: REST Methods
    def delete(path, data = {})
      connection.delete(path.to_s, data)
    end

    ##
    # Issues a query to FaunaDB.
    #
    # Queries are built via the Query helpers. See {FaunaDB Query API}[https://faunadb.com/documentation/queries]
    # for information on constructing queries.
    #
    # +expression+:: A query expression
    #
    # :category: Query Methods
    def query(expression = nil, &block)
      if block.nil?
        post('', expression)
      else
        post('', Fauna.query(&block))
      end
    end

    ##
    # Ping FaunaDB.
    #
    # Reference: {FaunaDB Rest API}[https://faunadb.com/documentation#rest-other].
    #
    # :category: REST Methods
    def ping(params = {})
      get 'ping', params
    end
  end
end
