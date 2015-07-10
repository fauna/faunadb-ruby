module Fauna
  class Client
    def initialize(connection)
      self.connection = connection
    end

    def query(expression)
      body = JSON.dump(expression)

      parse(connection.post('', body))
    end

    private
    def deserialize(obj)
      if obj.is_a?(Hash) && obj.include?(%w(@ref @set @obj))
        if obj['@ref']
          Ref.new(obj['@ref'])
        elsif obj['@obj']
          obj['@obj']
        end
      else
        obj
      end
    end

    def parse_json(body)
      JSON.load(body, &method(:deserialize)) unless body.empty?
    end

    def parse(response)
      body = parse_json(response.body)
      error_body = body || "Status #{response.status}"

      case response.status
        when 200..299
          body
        when 400
          raise BadRequest(error_body)
        when 401
          raise Unauthorized(error_body)
        when 403
          raise PermissionDenied(error_body)
        when 404
          raise NotFound(error_body)
        when 405
          raise MethodNotAllowed(error_body)
        when 500
          raise InternalError(error_body)
        when 503
          raise UnavailableError(error_body)
        else
          raise FaunaError(error_body)
      end
    end
  end
end
