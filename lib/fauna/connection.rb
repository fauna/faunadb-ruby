module Fauna
  class Connection # rubocop:disable Metrics/ClassLength
    class Error < RuntimeError
      attr_reader :error, :reason, :parameters

      def initialize(error, reason = nil, parameters = {})
        if error.is_a?(Hash)
          json = error
          @error = json['error']
          @reason = json['reason']
          @parameters = json['parameters'] || {}
        else
          @error = error
          @reason = reason
          @parameters = parameters
        end

        super(@reason || @error)
      end
    end

    class NotFound < Error; end
    class BadRequest < Error; end
    class Unauthorized < Error; end
    class PermissionDenied < Error; end
    class MethodNotAllowed < Error; end
    class NetworkError < Error; end

    attr_reader :domain, :scheme, :port, :credentials, :timeout, :connection_timeout, :adapter, :logger

    def initialize(params = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      @logger = params[:logger] || nil
      @domain = params[:domain] || 'rest1.fauna.org'
      @scheme = params[:scheme] || 'https'
      @port = params[:port] || (@scheme == 'https' ? 443 : 80)
      @timeout = params[:timeout] || 60
      @connection_timeout = params[:connection_timeout] || 60
      @adapter = params[:adapter] || Faraday.default_adapter
      @credentials = params[:secret].to_s.split(':')

      if ENV['FAUNA_DEBUG']
        @logger = Logger.new(STDERR)
        @logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      end

      @conn = Faraday.new(
        :url => "#{@scheme}://#{@domain}:#{@port}/",
        :headers => { 'Accept-Encoding' => 'gzip', 'Content-Type' => 'application/json;charset=utf-8' },
        :request => { :timeout => @timeout, :open_timeout => @connection_timeout },
      ) do |conn|
        conn.adapter(@adapter)
        conn.basic_auth(@credentials[0].to_s, @credentials[1].to_s)
      end
    end

    def get(ref, query = {})
      parse(*execute(:get, ref, nil, query))
    end

    def post(ref, data = {})
      parse(*execute(:post, ref, data))
    end

    def put(ref, data = {})
      parse(*execute(:put, ref, data))
    end

    def patch(ref, data = {})
      parse(*execute(:patch, ref, data))
    end

    def delete(ref, data = {})
      execute(:delete, ref, data)
      nil
    end

  private

    def parse(headers, body)
      obj = body.empty? ? {} : JSON.parse(body)
      obj.merge!('headers' => headers)
      obj
    end

    def log(indent)
      lines = Array(yield).collect { |string| string.split("\n") }
      lines.flatten.each { |line| @logger.debug(' ' * indent + line) }
    end

    def query_string_for_logging(query)
      return unless query && !query.empty?

      '?' + query.collect do |k, v|
        "#{k}=#{v}"
      end.join('&')
    end

    def inflate(response)
      if %w(gzip deflate).include?(response.headers['Content-Encoding'])
        Zlib::GzipReader.new(StringIO.new(response.body.to_s), :external_encoding => Encoding::UTF_8).read
      else
        response.body.to_s
      end
    end

    def execute(action, ref, data = nil, query = nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      if @logger
        log(0) { "Fauna #{action.to_s.upcase} /#{ref}#{query_string_for_logging(query)}" }
        log(2) { "Credentials: #{@credentials}" }
        log(2) { "Request JSON: #{JSON.pretty_generate(data)}" } if data

        t0, r0 = Process.times, Time.now
        response = execute_without_logging(action, ref, data, query)
        t1, r1 = Process.times, Time.now
        body = inflate(response)

        real = r1.to_f - r0.to_f
        cpu = (t1.utime - t0.utime) + (t1.stime - t0.stime) + (t1.cutime - t0.cutime) + (t1.cstime - t0.cstime)
        log(2) { ["Response headers: #{JSON.pretty_generate(response.headers)}", "Response JSON: #{body}"] }
        log(2) { "Response (#{response.status}): API processing #{response.headers['X-HTTP-Request-Processing-Time']}ms, network latency #{((real - cpu) * 1000).to_i}ms, local processing #{(cpu * 1000).to_i}ms" }
      else
        response = execute_without_logging(action, ref, data, query)
        body = inflate(response)
      end

      case response.status
      when 200..299
        [response.headers, body]
      when 400
        fail BadRequest.new(JSON.parse(body))
      when 401
        fail Unauthorized.new(JSON.parse(body))
      when 403
        fail PermissionDenied.new(JSON.parse(body))
      when 404
        fail NotFound.new(JSON.parse(body))
      when 405
        fail MethodNotAllowed.new(JSON.parse(body))
      else
        fail NetworkError, body
      end
    end

    def execute_without_logging(action, ref, data, query)
      @conn.send(action) do |req|
        req.params = query if query.is_a?(Hash)
        req.body = data.to_json if data.is_a?(Hash)
        req.url(ref || '')
      end
    end
  end
end
