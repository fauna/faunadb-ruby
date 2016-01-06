module Fauna
  class RequestResult
    # The Client.
    attr_reader :client
    # :get, :post, :put, :patch, or :delete
    attr_reader :method
    # Path that was queried. Relative to client's domain.
    attr_reader :path
    # URL query. <code>nil</code> unless <code>method == :get</code>. *Not* related to +Client.query+.
    attr_reader :query
    # Request data.
    attr_reader :request_content
    ##
    # Value returned by the response.
    # Includes "resource" wrapper hash, or may be an "errors" hash instead.
    attr_reader :response_content
    # HTTP status code.
    attr_reader :status_code
    # A hash of headers.
    attr_reader :response_headers
    # Time the request started.
    attr_reader :start_time
    # Time the response was received.
    attr_reader :end_time

    def initialize(
        client,
        method, path, query, request_content,
        response_content, status_code, response_headers,
        start_time, end_time)
      @client = client
      @method = method
      @path = path
      @query = query
      @request_content = request_content
      @response_content = response_content
      @status_code = status_code
      @response_headers = response_headers
      @start_time = start_time
      @end_time = end_time
    end

    # <code>end_time - start_time</code>
    def time_taken
      end_time - start_time
    end

    # Credentials used by the client.
    def auth
      client.instance_variable_get(:@connection).instance_variable_get :@credentials
    end
  end
end
