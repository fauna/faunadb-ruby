module Fauna
  class Connection
    API_VERSION = 0

    attr_accessor :publisher_key, :client_key, :username, :password, :logger, :log_response

    def initialize(params={})
      params.each do |attr, value|
        self.send("#{attr}=", value)
      end if params
    end

    def get(ref, key = :publisher, password = "")
      log("GET", ref) do
        RestClient.get(url(ref, key, password))
      end
    end

    def post(ref, data = {}, key = :publisher, password = "")
      log("POST", ref, data) do
        RestClient.post(url(ref, key, password), data.to_json, :content_type => :json)
      end
    end

    def put(ref, data = {}, key = :publisher, password = "")
      log("PUT", ref, data) do
        RestClient.put(url(ref, key, password), data.to_json, :content_type => :json)
      end
    end

    def delete(ref, data = {}, key = :publisher, password = "")
      log("DELETE", ref, data) do
        RestClient::Request.execute(:method => :delete, :url => url(ref, key, password),
                                  :payload => data.to_json, :headers => {:content_type => :json})
      end
    end

    def log(action, ref, data = nil)
      if @logger
        @logger.debug "  Fauna #{action} \"#{ref}\"#{"    --> \n"+data.inspect if data}"
        res = nil
        tms = Benchmark.measure { res = yield }
        @logger.debug "#{res.headers.inspect}\n#{res.to_s}" if @log_response
        @logger.debug "    --> #{res.code}: API processing #{res.headers[:x_time_total]}ms, network latency #{((tms.real - tms.total)*1000).to_i}ms, local processing #{(tms.total*1000).to_i}ms"
        res
      else
        yield
      end
    end

    def url(ref, user, pass = "")
      user = publisher_key if user == :publisher
      user = client_key if user == :client

      user = CGI.escape user
      pass = CGI.escape pass
      ref = ref.sub(%r|^/?|, '/')

      "https://#{user}:#{pass}@rest.fauna.org/v#{API_VERSION}#{ref}"
    end
  end
end
