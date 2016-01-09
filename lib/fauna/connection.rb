module Fauna
  class Connection # :nodoc:
    def initialize(client, params = {})
      @client = client

      @observer = params[:observer]
      domain = params[:domain] || 'rest.faunadb.com'
      scheme = params[:scheme] || 'https'
      port = params[:port] || (scheme == 'https' ? 443 : 80)
      timeout = params[:timeout] || 60
      connection_timeout = params[:connection_timeout] || 60
      adapter = params[:adapter] || Faraday.default_adapter
      # Stored in a user/pass pair as an Array.
      credentials = params[:secret].to_s.split(':', 2)

      # Create connection
      @connection = Faraday.new(
        url: "#{scheme}://#{domain}:#{port}/",
        headers: { 'Accept-Encoding' => 'gzip,deflate', 'Content-Type' => 'application/json;charset=utf-8' },
        request: { timeout: timeout, open_timeout: connection_timeout },
      ) do |conn|
        # Let us specify arguments so we can set stubs for test adapter
        conn.adapter(*Array(adapter))
        conn.basic_auth(credentials[0].to_s, credentials[1].to_s)
        conn.response :fauna_decode
      end
    end

    def get(path, query = {})
      execute(:get, path, query)
    end

    def post(path, data = {})
      execute(:post, path, nil, data)
    end

    def put(path, data = {})
      execute(:put, path, nil, data)
    end

    def patch(path, data = {})
      execute(:patch, path, nil, data)
    end

    def delete(path, data = {})
      execute(:delete, path, nil, data)
    end

  private

    def execute(action, path, query = nil, data = nil)
      start_time = Time.now
      response = perform_request action, path, query, data
      end_time = Time.now
      response_dict = FaunaJson.deserialize response.body unless response.body.nil?

      request_result = RequestResult.new @client,
        action, path, query, data,
        response_dict, response.status, response.headers,
        start_time, end_time

      @observer.call(request_result) unless @observer.nil?

      FaunaError.raise_for_status_code(request_result)
      response_dict[:resource]
    end

    def perform_request(action, path, query, data)
      @connection.send(action) do |req|
        req.params = query.delete_if { |_, v| v.nil? } unless query.nil?
        req.body = FaunaJson.to_json(data) unless data.nil?
        req.url(path || '')
      end
    end
  end

  # Middleware for decoding fauna responses
  class FaunaDecode < Faraday::Middleware # :nodoc:
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
        response_env[:body] = FaunaJson.json_load(response_env[:body]) unless response_env[:body].empty?
      end
    end
  end

  Faraday::Response.register_middleware fauna_decode: lambda { FaunaDecode }
end
