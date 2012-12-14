module Fauna
  class Connection
    API_VERSION = 0

    attr_accessor :publisher_key, :client_key, :username, :password

    def initialize(params={})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end if params
    end

    def get(ref, key = :publisher, password = "")
      RestClient.get(url(ref, key, password))
    end

    def post(ref, data, key = :publisher, password = "")
      RestClient.post(url(ref, key, password), data.to_json, :content_type => :json)
    end

    def put(ref, data, key = :publisher, password = "")
      RestClient.put(url(ref, key, password), data.to_json, :content_type => :json)
    end

    def delete(ref, key = :publisher, password = "")
      RestClient.delete(url(ref, key, password))
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
