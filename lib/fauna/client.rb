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

    def handle_errors(response)
      case response.status
        when 200.299
          nil
        when 400
          raise BadRequest(parse_json(response.body))
        when 401
          raise Unauthorized(parse_json(response.body))
        when 403
          raise PermissionDenied(parse_json(response.body))
        when 404
          raise NotFound(parse_json(response.body))
        when 405
          raise MethodNotAllowed(parse_json(response.body))
        when 500
          raise InternalError(parse_json(response.body))
        when 503
          raise UnavailableError(parse_json(response.body))
      end
    end

    def parse(response)
      handle_errors(response)
      parse_json(response.body)
    end
  end
end
