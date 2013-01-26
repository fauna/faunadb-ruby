module Fauna
  class Connection
    API_VERSION = 0

    class Error < StandardError
    end

    class NotFound < Error
    end

    class BadRequest < Error
    end

    class Unauthorized < Error
    end

    class NetworkError < Error
    end

    HANDLER = Proc.new do |res, _, _|
      case res.code
      when 200, 201, 204
        res
      when 404
        raise NotFound, JSON.parse(res)
      when 400
        raise BadRequest, JSON.parse(res)
      when 401
        raise Unauthorized, JSON.parse(res)
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

    def get(ref)
      JSON.parse(
        log("GET", ref) do
          RestClient.get(
            url(ref),
          &HANDLER)
        end
      )
    end

    def post(ref, data = {})
      JSON.parse(
        log("POST", ref, data) do
          RestClient.post(
            url(ref),
            data.to_json,
            :content_type => :json,
          &HANDLER)
        end
      )
    end

    def put(ref, data = {})
      JSON.parse(
        log("PUT", ref, data) do
          RestClient.put(
            url(ref),
            data.to_json,
            :content_type => :json,
          &HANDLER)
        end
      )
    end

    def delete(ref, data = {})
      log("DELETE", ref, data) do
        RestClient::Request.execute(
          :method => :delete,
          :url => url(ref),
          :payload => data.to_json,
          :headers => {:content_type => :json},
        &HANDLER)
      end
      nil
    end

    private

    def log(action, ref, data = nil)
      if @logger
        @logger.debug "  Fauna #{action} \"#{ref}\"#{"    --> \n"+data.inspect if data}"
        res = nil
        tms = Benchmark.measure { res = yield }
        @logger.debug "#{res.headers.inspect}\n#{res.to_s}" if @debug
        @logger.debug "    --> #{res.code}: API processing #{res.headers[:x_time_total]}ms, network latency #{((tms.real - tms.total)*1000).to_i}ms, local processing #{(tms.total*1000).to_i}ms"
        res
      else
        yield
      end
    end

    def url(ref)
      "https://#{@credentials}@rest.fauna.org/v#{API_VERSION}/#{ref}"
    end
  end
end
