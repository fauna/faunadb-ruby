module Fauna
  class Connection # rubocop:disable Metrics/ClassLength
    attr_reader :domain, :scheme, :port, :credentials, :timeout, :connection_timeout, :adapter, :logger

    def initialize(params = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      @logger = Array.new
      @domain = params[:domain] || 'rest.faunadb.com'
      @scheme = params[:scheme] || 'https'
      @port = params[:port] || (@scheme == 'https' ? 443 : 80)
      @timeout = params[:timeout] || 60
      @connection_timeout = params[:connection_timeout] || 60
      @adapter = params[:adapter] || Faraday.default_adapter
      @credentials = params[:secret].to_s.split(':', 2)

      unless params[:logger].nil?
        @logger.push params[:logger]
      end

      if ENV['FAUNA_DEBUG']
        debug_logger = Logger.new(STDERR)
        debug_logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
        @logger.push debug_logger
      end

      # Create connection
      @conn = Faraday.new(
          url: "#{@scheme}://#{@domain}:#{@port}/",
          headers: { 'Accept-Encoding' => 'gzip,deflate', 'Content-Type' => 'application/json;charset=utf-8' },
          request: { timeout: @timeout, open_timeout: @connection_timeout }
      ) do |conn|
        conn.adapter(@adapter)
        conn.basic_auth(@credentials[0].to_s, @credentials[1].to_s)
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
      nil
    end

  private

    def log(indent)
      lines = Array(yield).collect { |string| string.split("\n") }
      lines.flatten.each { |line|
        line = ' ' * indent + line
        @logger.each { |logger| logger.debug(line) }
      }
    end

    def query_string_for_logging(query)
      return unless query && !query.empty?

      '?' + query.collect do |k, v|
        "#{k}=#{v}"
      end.join('&')
    end

    def decompress(response)
      case response.headers['Content-Encoding']
        when 'gzip'
          # noinspection RubyArgCount
          response.body = Zlib::GzipReader.new(StringIO.new(response.body), external_encoding: Encoding::UTF_8)
        when 'deflate'
          response.body = Zlib::Inflate.inflate(response.body)
      end
    end

    def execute(action, path, query = nil, data = nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      if @logger
        log(0) { "Fauna #{action.to_s.upcase} /#{path}#{query_string_for_logging(query)}" }
        log(2) { "Credentials: #{@credentials}" }
        log(2) { "Request JSON: #{JSON.pretty_generate(data)}" } if data

        t0 = Time.now
        response = execute_without_logging(action, path, data, query)
        t1 = Time.now

        decompress(response)

        network_latency = t1.to_f - t0.to_f
        log(2) { ["Response headers: #{JSON.pretty_generate(response.headers)}", "Response JSON: #{response.body}"] }
        log(2) { "Response (#{response.status}): API processing #{response.headers['X-HTTP-Request-Processing-Time']}ms, network latency #{(network_latency * 1000).to_i}ms" }
      else
        response = execute_without_logging(action, path, data, query)
        inflate(response)
      end

      response
    end

    def execute_without_logging(action, path, query, data)
      @conn.send(action) do |req|
        req.params = query if query.is_a?(Hash)
        req.body = data.to_json if data.is_a?(Hash)
        req.url(path || '')
      end
    end
  end
end
