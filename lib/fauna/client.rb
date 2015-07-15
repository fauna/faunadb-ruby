module Fauna
  class Client
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def get(path, query = {})
      parse(connection.get(path, query))
    end

    def post(path, data = {})
      parse(connection.post(path, data))
    end

    def put(path, data = {})
      parse(connection.put(path, data))
    end

    def patch(path, data = {})
      parse(connection.patch(path, data))
    end

    def delete(path, data = {})
      parse(connection.delete(path, data))
    end

    def query(expression)
      methods = %w(get create update replace delete)
      classes = %w(databases keys)

      methods.each do |method|
        ref = expression[method]
        if ref
          fauna_class = ref.to_class.ref
          if classes.include?(fauna_class)
            ref = ref.ref
            case method
              when 'get'
                return get(ref, ts: expression['ts'])
              when 'create'
                raise InvalidQuery("#{fauna_class} does not support object, use quote") unless expression['params']['object'].nil?
                return post(ref, expression['params']['quote'])
              when 'update'
                raise InvalidQuery("#{fauna_class} does not support object, use quote") unless expression['params']['object'].nil?
                return patch(ref, expression['params']['quote'])
              when 'replace'
                raise InvalidQuery("#{fauna_class} does not support object, use quote") unless expression['params']['object'].nil?
                return put(ref, expression['params']['quote'])
              when 'delete'
                return delete(ref)
            end
          end
        end
      end

      post('', expression)
    end

    private
    def deserialize(obj)
      if obj.is_a?(Hash)
        if obj.has_key? '@ref'
          Ref.new(obj['@ref'])
        elsif obj.has_key? '@set'
          Set.new(obj['@set']['match'], obj['@set']['match'])
        elsif obj.has_key? '@obj'
          Obj.new.merge(obj['@obj'])
        else
          obj.update(obj) { |_, v| deserialize(v) }
        end
      else
        obj
      end
    end

    def parse_json(body)
      deserialize(JSON.load(body)) unless body.empty?
    end

    def parse(response)
      body = parse_json(response.body)
      error_body = body || "Status #{response.status}"

      case response.status
        when 200..299
          body
        when 400
          raise BadRequest.new(error_body)
        when 401
          raise Unauthorized.new(error_body)
        when 403
          raise PermissionDenied.new(error_body)
        when 404
          raise NotFound.new(error_body)
        when 405
          raise MethodNotAllowed.new(error_body)
        when 500
          raise InternalError.new(error_body)
        when 503
          raise UnavailableError.new(error_body)
        else
          raise FaunaError.new(error_body)
      end
    end
  end
end
