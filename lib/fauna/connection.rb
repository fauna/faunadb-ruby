module Fauna
  class Connection
    API_VERSION = 0

    def initialize(params={})
      if ENV["FAUNA_DEBUG"] or ENV["FAUNA_DEBUG_RESPONSE"]
        @logger = Logger.new(STDERR)
        @debug = true if ENV["FAUNA_DEBUG_RESPONSE"]
      end

      @logger = params[:logger] || nil

      # Check credentials from least to most privileged, in case
      # multiple were provided
      @credentials = if params[:token]
        CGI.escape(@key = params[:token])
      elsif params[:client_key]
        CGI.escape(params[:client_key])
      elsif params[:publisher_key]
        CGI.escape(params[:publisher_key])
      elsif params[:username] and params[:password]
        "#{CGI.escape(params[:username])}:#{CGI.escape(params[:password])}"
      else
        raise ArgumentError, "Credentials not defined."
      end
    end

    def get(ref)
      log("GET", ref) { JSON.parse(RestClient.get(url(ref))) }
    end

    def post(ref, data)
      log("POST", ref, data) { JSON.parse(RestClient.post(url(ref), data.to_json, :content_type => :json)) }
    end

    def put(ref, data)
      log("PUT", ref, data) { JSON.parse(RestClient.put(url(ref), data.to_json, :content_type => :json)) }
    end

    def delete(ref, data)
      log("DELETE", ref, data) do
        JSON.parse(RestClient::Request.execute(:method => :delete, :url => url(ref),
                                    :payload => data.to_json, :headers => {:content_type => :json}))
      end
    end

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
      "https://#{@credentials}@rest.fauna.org/v#{API_VERSION}#{ref}"
    end
  end
end
