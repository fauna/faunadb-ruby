module Fauna
  ##
  # Error raised when the context is used without a client being set.
  class NoContextError < RuntimeError; end

  ##
  # Error returned by the FaunaDB server.
  # For documentation of error types, see the `docs <https://faunadb.com/documentation#errors>`__.
  class FaunaError < RuntimeError
    ##
    # Either an error or a list of errors representing the fault encountered.
    # Can also be a simple message.
    attr_reader :errors

    # +RequestResult+ for the request that caused this error.
    attr_reader :request_result

    def self.raise_for_status_code(request_result)
      case request_result.status_code
      when 200..299

      when 400
        fail BadRequest.new(request_result)
      when 401
        fail Unauthorized.new(request_result)
      when 403
        fail PermissionDenied.new(request_result)
      when 404
        fail NotFound.new(request_result)
      when 405
        fail MethodNotAllowed.new(request_result)
      when 500
        fail InternalError.new(request_result)
      when 503
        fail UnavailableError.new(request_result)
      else
        fail FaunaError.new(request_result)
      end
    end

    ##
    # Creates a new Fauna error
    #
    # +errors+:: Takes one of three forms:
    #            :: A hash with a list of errors under +errors+.
    #            :: A hash with a simple error.
    #            :: A simple string as the message.
    def initialize(request_result)
      @request_result = request_result

      errors = request_result.response_content
      if errors.is_a?(Hash)
        if errors.key?(:error)
          message = errors[:description] || errors[:error]
          @errors = [message]
        else
          errors = errors[:errors]
          message = errors.collect { |error| error[:code] }.join(',')
          @errors = errors
        end
      else
        message = errors
        @errors = nil
      end

      super(message)
    end
  end

  # An exception thrown if FaunaDB cannot evaluate a query.
  class BadRequest < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 401.
  class Unauthorized < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 403.
  class PermissionDenied < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 404 for non-query endpoints.
  class NotFound < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 405.
  class MethodNotAllowed < FaunaError; end

  ##
  # An exception thrown if FaunaDB responds with an HTTP 500. Such errors represent an internal
  # failure within the database.
  class InternalError < FaunaError; end

  ##
  # An exception thrown if FaunaDB responds with an HTTP 503.
  class UnavailableError < FaunaError; end

  ##
  # An exception thrown when an unsupported query is used. This currently only applies to
  # using +object+ within a +databases+ or +keys+ query.
  class InvalidQuery < FaunaError; end
end
