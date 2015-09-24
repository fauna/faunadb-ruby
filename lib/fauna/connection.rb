module Fauna
  ##
  # The HTTP connection for the Ruby FaunaDB client.
  # A Connection is automatically created by the Client and does not need to be used directly.
  #
  # Relies on Faraday[https://github.com/lostisland/faraday] as the underlying client.
  class Connection
    # The domain to send requests to.
    attr_reader :domain
    # Scheme to use when sending requests (either +http+ or +https+).
    attr_reader :scheme
    # Port to use when sending requests.
    attr_reader :port
    # Credentials to use when sending requests. Stored in a user/pass pair as an Array.
    attr_reader :credentials
    # Read timeout in seconds.
    attr_reader :timeout
    # \Connection open timeout in seconds.
    attr_reader :connection_timeout
    # Faraday adapter in use.
    attr_reader :adapter
    # List of loggers to record request/response data to.
    attr_reader :logger

    ##
    # Creates a new Connection object to be used in the creation of a FaunaDB client.
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
    def initialize(params = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      @loggers = []
      @domain = params[:domain] || 'rest.faunadb.com'
      @scheme = params[:scheme] || 'https'
      @port = params[:port] || (@scheme == 'https' ? 443 : 80)
      @timeout = params[:timeout] || 60
      @connection_timeout = params[:connection_timeout] || 60
      @adapter = params[:adapter] || Faraday.default_adapter
      @credentials = params[:secret].to_s.split(':', 2)

      @loggers.push params[:logger] unless params[:logger].nil?

      if ENV['FAUNA_DEBUG']
        debug_logger = Logger.new(STDERR)
        debug_logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
        @loggers.push debug_logger
      end

      # Create connection
      @connection = Faraday.new(
          url: "#{@scheme}://#{@domain}:#{@port}/",
          headers: { 'Accept-Encoding' => 'gzip,deflate', 'Content-Type' => 'application/json;charset=utf-8' },
          request: { timeout: @timeout, open_timeout: @connection_timeout },
      ) do |conn|
        # Let us specify arguments so we can set stubs for test adapter
        conn.adapter(*Array(@adapter))
        conn.basic_auth(@credentials[0].to_s, @credentials[1].to_s)
        conn.response :fauna_decode
      end
    end

    ##
    # Performs a +GET+ request.
    #
    # +path+:: Path to +GET+.
    # +query+:: A Hash of query parameters to append to the path.
    def get(path, query = {})
      execute(:get, path, query)
    end

    ##
    # Performs a +POST+ request.
    #
    # +path+:: Path to +POST+.
    # +data+:: The data to submit as the request body. +data+ is automatically converted to JSON.
    def post(path, data = {})
      execute(:post, path, nil, data)
    end

    ##
    # Performs a +PUT+ request.
    #
    # +path+:: Path to +PUT+.
    # +data+:: The data to submit as the request body. +data+ is automatically converted to JSON.
    def put(path, data = {})
      execute(:put, path, nil, data)
    end

    ##
    # Performs a +PATCH+ request.
    #
    # +path+:: Path to +PATCH+.
    # +data+:: The data to submit as the request body. +data+ is automatically converted to JSON.
    def patch(path, data = {})
      execute(:patch, path, nil, data)
    end

    ##
    # Performs a +DELETE+ request.
    #
    # +path+:: Path to +DELETE+.
    # +data+:: The data to submit as the request body. +data+ is automatically converted to JSON.
    def delete(path, data = {})
      execute(:delete, path, nil, data)
    end

  private

    def log(indent)
      lines = Array(yield).collect { |string| string.split("\n") }
      lines.flatten.each do |line|
        line = ' ' * indent + line
        @loggers.each { |logger| logger.debug(line) }
      end
    end

    def query_string_for_logging(query)
      return unless query && !query.empty?

      '?' + query.collect do |k, v|
        "#{k}=#{v}"
      end.join('&')
    end

    def execute(action, path, query = nil, data = nil) # rubocop:disable Metrics/MethodLength
      if @loggers.empty?
        response = execute_without_logging(action, path, query, data)
      else
        log(0) { "Fauna #{action.to_s.upcase} /#{path}#{query_string_for_logging(query)}" }
        log(2) { "Credentials: #{@credentials}" }
        log(2) { "Request JSON: #{JSON.pretty_generate(data)}" } if data

        t0 = Time.now
        response = execute_without_logging(action, path, query, data)
        t1 = Time.now

        network_latency = t1.to_f - t0.to_f
        log(2) { ["Response headers: #{JSON.pretty_generate(response.headers)}", "Response JSON: #{JSON.pretty_generate(response.body)}"] }
        log(2) { "Response (#{response.status}): API processing #{response.headers['X-HTTP-Request-Processing-Time']}ms, network latency #{(network_latency * 1000).to_i}ms" }
      end

      response
    end

    def execute_without_logging(action, path, query, data)
      @connection.send(action) do |req|
        req.params = query.delete_if { |_, v| v.nil? } unless query.nil?
        req.body = data.to_json unless data.nil?
        req.url(path || '')
      end
    end
  end

  # :nodoc:
  # Middleware for decoding fauna responses
  class FaunaDecode < Faraday::Middleware
    # :nodoc:
    def call(env)
      @app.call(env).on_complete do |response_env|
        # Decompress
        case response_env[:response_headers]['Content-Encoding']
        when 'gzip'
          # noinspection RubyArgCount
          response_env[:body] = Zlib::GzipReader.new(StringIO.new(response.body), external_encoding: Encoding::UTF_8)
        when 'deflate'
          response_env[:body] = Zlib::Inflate.inflate(response.body)
        end

        # Parse JSON
        response_env[:body] = json_load(response_env[:body]) unless response_env[:body].empty?
      end
    end

  private

    def json_load(body)
      JSON.load body, nil, max_nesting: false, symbolize_names: true
    end
  end

  Faraday::Response.register_middleware fauna_decode: lambda { FaunaDecode }
end
