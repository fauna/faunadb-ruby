module Fauna
  class Connection
    class Error < RuntimeError
      attr_reader :param_errors

      def initialize(message, param_errors = {})
        @param_errors = param_errors
        super(message)
      end
    end

    class NotFound < Error; end
    class BadRequest < Error; end
    class Unauthorized < Error; end
    class NotAllowed < Error; end
    class NetworkError < Error; end

    HANDLER = Proc.new do |res, _, _|
      case res.code
      when 200..299
        res
      when 400
        json = JSON.parse(res.body)
        raise BadRequest.new(json['error'], json['param_errors'])
      when 401
        raise Unauthorized, JSON.parse(res.body)['error']
      when 404
        raise NotFound, JSON.parse(res.body)['error']
      when 405
        raise NotAllowed, JSON.parse(res.body)['error']
      else
        raise NetworkError, res.body
      end
    end

    attr_reader :domain, :scheme, :port, :credentials

    def initialize(params={})
      @logger = params[:logger] || nil
      @domain = params[:domain] || "rest1.fauna.org"
      @scheme = params[:scheme] || "https"
      @port = params[:port] || (@scheme == "https" ? 443 : 80)

      if ENV["FAUNA_DEBUG"]
        @logger = Logger.new(STDERR)
        @debug = true
      end
      @credentials = params[:secret].to_s
    end

    def get(ref, query = {})
      parse(execute(:get, ref, nil, query))
    end

    def post(ref, data = {})
      parse(execute(:post, ref, data))
    end

    def put(ref, data = {})
      parse(execute(:put, ref, data))
    end

    def patch(ref, data = {})
      parse(execute(:patch, ref, data))
    end

    def delete(ref, data = {})
      execute(:delete, ref, data)
      nil
    end

    private

    def parse(res)
      obj = res.body.to_s.empty? ? {} : JSON.parse(res.body)
      obj.merge!("headers" => res.headers)
      obj
    end

    def log(indent)
      Array(yield).map do |string|
        string.split("\n")
      end.flatten.each do |line|
        @logger.debug(" " * indent + line)
      end
    end

    def query_string_for_logging(query)
      if query && !query.empty?
        "?" + query.map do |k,v|
          "#{k}=#{v}"
        end.join("&")
      end
    end

    def execute(action, ref, data = nil, query = nil)
      request = Typhoeus::Request.new(url(ref), :method => action)
      request.options[:params] = query if query.is_a?(Hash)

      if data.is_a?(Hash)
        request.options[:headers] = { "Content-Type" => "application/json;charset=utf-8" }
        request.options[:body] = data.to_json
      end

      if @logger
        log(2) { "Fauna #{action.to_s.upcase} /#{ref}#{query_string_for_logging(query)}" }
        log(4) { "Credentials: #{@credentials}" } if @debug
        log(4) { "Request JSON: #{JSON.pretty_generate(data)}" } if @debug && data

        t0, r0 = Process.times, Time.now
        request.run
        t1, r1 = Process.times, Time.now

        real = r1.to_f - r0.to_f
        cpu = (t1.utime - t0.utime) + (t1.stime - t0.stime) + (t1.cutime - t0.cutime) + (t1.cstime - t0.cstime)
        log(4) { ["Response headers: #{JSON.pretty_generate(request.response.headers)}", "Response JSON: #{request.response.body}"] } if @debug
        log(4) { "Response (#{request.response.code}): API processing #{request.response.headers["X-HTTP-Request-Processing-Time"]}ms, network latency #{((real - cpu)*1000).to_i}ms, local processing #{(cpu*1000).to_i}ms" }
      else
        request.run
      end
      HANDLER.call(request.response)
    end

    def url(ref)
      "#{@scheme}://#{@credentials}@#{@domain}:#{@port}/#{ref}"
    end
  end
end
