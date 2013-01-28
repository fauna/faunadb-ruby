module Fauna
  class Connection
    API_VERSION = 0

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
        json = JSON.parse(res)
        raise BadRequest.new(json['error'], json['param_errors'])
      when 401
        raise Unauthorized, JSON.parse(res)['error']
      when 404
        raise NotFound, JSON.parse(res)['error']
      when 405
        raise NotAllowed, JSON.parse(res)['error']
      else
        raise NetworkError, res
      end
    end

    def initialize(params={})
      @logger = params[:logger] || nil

      if ENV["FAUNA_DEBUG"] or ENV["FAUNA_DEBUG_RESPONSE"]
        @logger ||= Logger.new(STDERR)
        @debug = true if ENV["FAUNA_DEBUG_RESPONSE"]
      end

      # Check credentials from least to most privileged, in case
      # multiple were provided
      @credentials = if params[:token]
        CGI.escape(@key = params[:token])
      elsif params[:client_key]
        CGI.escape(params[:client_key])
      elsif params[:publisher_key]
        CGI.escape(params[:publisher_key])
      elsif params[:email] and params[:password]
        "#{CGI.escape(params[:email])}:#{CGI.escape(params[:password])}"
      else
        raise ArgumentError, "Credentials not defined."
      end
    end

    def get(ref, query = nil)
      JSON.parse(execute(:get, ref, nil, query))
    end

    def post(ref, data = nil)
      JSON.parse(execute(:post, ref, data))
    end

    def put(ref, data = nil)
      JSON.parse(execute(:put, ref, data))
    end

    def patch(ref, data = nil)
      JSON.parse(execute(:patch, ref, data))
    end

    def delete(ref, data = nil)
      execute(:delete, ref, data)
      nil
    end

    private

      def log(indent)
        Array(yield).map do |string|
          string.split("\n")
        end.flatten.each do |line|
          @logger << " " * indent
          @logger << line
          @logger << "\n"
        end
      end

    def execute(action, ref, data = nil, query = nil)
      args = { :method => action, :url => url(ref), :headers => {} }

      if query
        args[:headers].merge! :params => query
      end

      if data
        args[:headers].merge! :content_type => :json
        args.merge! :payload => data.to_json
      end

      if @logger
        log(2) { "Fauna #{action.to_s.upcase}(\"#{ref}\")" }
        log(4) { "Request query: #{JSON.pretty_generate(query)}" } if query
        log(4) { "Request JSON: #{JSON.pretty_generate(data)}" } if data

        t0, r0 = Process.times, Time.now

        RestClient::Request.execute(args) do |res, _, _|
          t1, r1 = Process.times, Time.now
          real = r1.to_f - r0.to_f
          cpu = (t1.utime - t0.utime) + (t1.stime - t0.stime) + (t1.cutime - t0.cutime) + (t1.cstime - t0.cstime)
          log(4) { ["Response headers: #{JSON.pretty_generate(res.headers)}", "Response JSON: #{res}"] } if @debug
          log(4) { "Response (#{res.code}): API processing #{res.headers[:x_time_total]}ms, network latency #{((real - cpu)*1000).to_i}ms, local processing #{(cpu*1000).to_i}ms" }

          HANDLER.call(res)
        end
      else
        RestClient::Request.execute(args, &HANDLER)
      end
    end

    def url(ref)
      "https://#{@credentials}@rest.fauna.org/v#{API_VERSION}/#{ref}"
    end
  end
end
