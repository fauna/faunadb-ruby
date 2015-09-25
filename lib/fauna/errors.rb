module Fauna
  ##
  # Base error type for Fauna-related errors.
  class FaunaError < RuntimeError
    ##
    # Either an error or a list of errors representing the fault encountered.
    # Can also be a simple message.
    attr_reader :errors

    ##
    # Creates a new Fauna error
    #
    # +errors+:: Takes one of three forms:
    #            :: A hash with a list of errors under +errors+.
    #            :: A hash with a simple error.
    #            :: A simple string as the message.
    def initialize(errors)
      if errors.is_a?(Hash)
        if errors.key?('error')
          message = errors['description'] || errors['error']
          @errors = [message]
        else
          errors = errors['errors']
          message = errors.collect { |error| error['code'] }.join(',')
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

  ##
  # Error raised when the context is used without a client being set.
  class NoContextError < FaunaError; end
end
