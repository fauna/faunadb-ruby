module Fauna
  ##
  # The Ruby client for FaunaDB.
  #
  # All methods return a converted JSON response.
  # This is a Hash containing Arrays, ints, floats, strings, and other Hashes.
  # Hash keys are always Symbols.
  #
  # Any Ref, SetRef, Time or Date values in it will also be parsed.
  # (So instead of <code>{ "@ref": "classes/frogs/123" }</code>,
  # you will get <code>Fauna::Ref.new("classes/frogs/123")</code>).
  class Client
    # The domain requests will be sent to.
    attr_reader :domain
    # Scheme used when sending requests (either +http+ or +https+).
    attr_reader :scheme
    # Port used when sending requests.
    attr_reader :port
    # An array of the user and pass used for authentication when sending requests.
    attr_reader :credentials
    # Read timeout in seconds.
    attr_reader :read_timeout
    # Open timeout in seconds.
    attr_reader :connection_timeout
    # Callback that will be passed a +RequestResult+ after every completed request.
    attr_reader :observer
    # Faraday[https://github.com/lostisland/faraday] adapter in use.
    attr_reader :adapter

    ##
    # Create a new Client.
    #
    # +params+:: A list of parameters to configure the connection with.
    #            +:domain+:: The domain to send requests to.
    #            +:scheme+:: Scheme to use when sending requests (either +http+ or +https+).
    #            +:port+:: Port to use when sending requests.
    #            +:secret+:: Credentials to use when sending requests. User and pass must be separated by a colon.
    #            +:read_timeout+:: Read timeout in seconds.
    #            +:connection_timeout+:: Open timeout in seconds.
    #            +:observer+:: Callback that will be passed a RequestResult after every completed request.
    #            +:adapter+:: Faraday[https://github.com/lostisland/faraday] adapter to use. Either can be a symbol for the adapter, or an array of arguments.
    def initialize(params = {})
      @domain = params[:domain] || 'db.fauna.com'
      @scheme = params[:scheme] || 'https'
      @port = params[:port] || (scheme == 'https' ? 443 : 80)
      @read_timeout = params[:read_timeout] || 60
      @connection_timeout = params[:connection_timeout] || 60
      @observer = params[:observer]
      @adapter = params[:adapter] || :net_http_persistent
      init_credentials(params[:secret])

      init_connection
    end

    ##
    # Create a new client from the existing config with a given secret.
    #
    # +:secret+:: Credentials to use when sending requests. User and pass must be separated by a colon.
    def with_secret(secret)
      with_dup do |client|
        client.send(:init_credentials, secret)
      end
    end

    ##
    # Issues a query to FaunaDB.
    #
    # Queries are built via the Query helpers. See {FaunaDB Query API}[https://fauna.com/documentation/queries]
    # for information on constructing queries.
    #
    # +expression+:: A query expression
    # +expr_block+:: May be provided instead of expression. Block is used to build an expression with Fauna.query.
    #
    # Example using expression:
    #
    # <code>client.query(Fauna::Query.add(1, 2, Fauna::Query.subtract(3, 2)))</code>
    #
    # Example using block:
    #
    # <code>client.query { add(1, 2, subtract(3, 2)) }</code>
    #
    # Reference: {Executing FaunaDB Queries}[https://fauna.com/documentation#queries]
    #
    # :category: Query Methods
    def query(expression = nil, &expr_block)
      if expr_block.nil?
        post '', Fauna::Query::Expr.wrap(expression)
      else
        post '', Fauna::Query.expr(&expr_block)
      end
    end

    ##
    # Creates a Fauna::Page for paging/iterating over a set.
    #
    # +set+:: A set query to paginate over.
    # +params+:: A list of parameters to pass to {paginate}[https://fauna.com/documentation/queries#read_functions-paginate_set].
    # +fauna_map+:: Optional block to wrap the generated paginate query with. The block will be run in a query context.
    #               The paginate query will be passed into the block as an argument.
    def paginate(set, params = {}, &fauna_map)
      Fauna::Page.new(self, set, params, &fauna_map)
    end

    ##
    # Performs a +GET+ request for a REST endpoint.
    #
    # +path+:: Path to +GET+.
    # +query+:: Query parameters to append to the path.
    #
    # Reference: {FaunaDB REST API}[https://fauna.com/documentation/rest]
    #
    # :category: REST Methods
    def get(path, query = {})
      execute(:get, path.to_s, query)
    end

    ##
    # Performs a +POST+ request for a REST endpoint.
    #
    # +path+:: Path to +POST+.
    # +data+:: Data to post as the body. +data+ is automatically converted to JSON.
    #
    # Reference: {FaunaDB REST API}[https://fauna.com/documentation/rest]
    #
    # :category: REST Methods
    def post(path, data = {})
      execute(:post, path, nil, data)
    end

    ##
    # Performs a +PUT+ request for a REST endpoint.
    #
    # +path+:: Path to +PUT+.
    # +data+:: Data to post as the body. +data+ is automatically converted to JSON.
    #
    # Reference: {FaunaDB REST API}[https://fauna.com/documentation/rest]
    #
    # :category: REST Methods
    def put(path, data = {})
      execute(:put, path, nil, data)
    end

    ##
    # Performs a +PATCH+ request for a REST endpoint.
    #
    # +path+:: Path to +PATCH+.
    # +data+:: Data to post as the body. +data+ is automatically converted to JSON.
    #
    # Reference: {FaunaDB REST API}[https://fauna.com/documentation/rest]
    #
    # :category: REST Methods
    def patch(path, data = {})
      execute(:patch, path, nil, data)
    end

    ##
    # Performs a +DELETE+ request for a REST endpoint.
    #
    # +path+:: Path to +DELETE+.
    #
    # Reference: {FaunaDB REST API}[https://fauna.com/documentation/rest]
    #
    # :category: REST Methods
    def delete(path)
      execute(:delete, path)
    end

    ##
    # Ping FaunaDB.
    #
    # Reference: {FaunaDB Rest API}[https://fauna.com/documentation#rest-other].
    #
    # :category: REST Methods
    def ping(params = {})
      get 'ping', params
    end

  private

    def with_dup
      new_client = self.dup
      yield new_client
      new_client.send(:init_connection)
      new_client
    end

    def init_credentials(secret)
      @credentials = secret.to_s.split(':', 2)
    end

    def init_connection
      @connection = Faraday.new(
        url: "#{scheme}://#{domain}:#{port}/",
        headers: {
          'Accept-Encoding' => 'gzip,deflate',
          'Content-Type' => 'application/json;charset=utf-8',
          'User-Agent' => "FaunaDB-Ruby/#{Fauna::VERSION}",
        },
        request: { timeout: read_timeout, open_timeout: connection_timeout },
      ) do |conn|
        # Let us specify arguments so we can set stubs for test adapter
        conn.adapter(*Array(adapter))
        conn.basic_auth(credentials[0].to_s, credentials[1].to_s)
        conn.response :fauna_decode
      end
    end

    def execute(action, path, query = nil, data = nil)
      path = path.to_s

      start_time = Time.now
      begin
        response = perform_request action, path, query, data
      rescue Faraday::ClientError => e
        end_time = Time.now

        message = e.class.name
        message += ": #{e.message}" unless e.message.nil?

        request_result = RequestResult.new(self,
            action, path, query, data,
            nil, nil, nil, nil,
            start_time, end_time)
        raise UnexpectedError.new(message, request_result)
      end
      end_time = Time.now

      response_raw = response.body
      response_json = FaunaJson.json_load_or_nil response_raw
      response_content = FaunaJson.deserialize response_json unless response_json.nil?

      request_result = RequestResult.new(self,
          action, path, query, data,
          response_raw, response_content, response.status, response.headers,
          start_time, end_time)

      @observer.call(request_result) unless @observer.nil?

      FaunaError.raise_for_status_code(request_result)
      UnexpectedError.get_or_raise request_result, response_content, :resource
    end

    def perform_request(action, path, query, data)
      @connection.send(action) do |req|
        req.params = query.delete_if { |_, v| v.nil? } unless query.nil?
        req.body = FaunaJson.to_json(data) unless data.nil?
        req.url(path || '')
      end
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError => e
      raise UnavailableError.new(e)
    end
  end

  # Middleware for decompressing responses
  class FaunaDecode < Faraday::Middleware # :nodoc:
    def call(env)
      @app.call(env).on_complete do |response_env|
        raw_body = response_env[:body]
        response_env[:body] =
          case response_env[:response_headers]['Content-Encoding']
          when 'gzip'
            io = StringIO.new raw_body
            Zlib::GzipReader.new(io, external_encoding: Encoding::UTF_8).read
          when 'deflate'
            Zlib::Inflate.inflate raw_body
          else
            raw_body
          end
      end
    end
  end

  Faraday::Response.register_middleware fauna_decode: lambda { FaunaDecode }
end
