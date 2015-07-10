module Fauna
  class FaunaError < RuntimeError; end

  class QueryError < FaunaError
    attr_reader :errors

    def initialize(errors)
      @errors = errors

      if error.is_a?(Hash)
        message = @errors.collect { |error| error['code'] }.join(',')
      else
        message = @errors
      end

      super(message)
    end
  end

  class NonQueryError < FaunaError
    attr_reader :error, :description, :stacktrace

    def initialize(error, description = nil, stacktrace = [])
      if error.is_a?(Hash)
        @error = error['error']
        @description = error['description']
        @stacktrace = error['stacktrace'] || []
      else
        @error = error
        @description = description
        @stacktrace = stacktrace
      end

      super(@description || @error)
    end
  end

  class UnavailableError < NonQueryError; end
  class UnknownFaunaError < NonQueryError; end

  class BadRequest < QueryError; end
  class Unauthorized < NonQueryError; end
  class PermissionDenied < NonQueryError; end
  class NotFound < NonQueryError; end
  class MethodNotAllowed < NonQueryError; end
  class InternalError < NonQueryError; end
end