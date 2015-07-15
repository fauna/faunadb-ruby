module Fauna
  class FaunaError < RuntimeError
    attr_reader :errors

    def initialize(errors)
      if errors.is_a?(Hash)
        if errors.has_key?('error')
          message = errors['description'] || errors['error']
          @errors = Array.new(message)
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

  class BadRequest < FaunaError; end
  class Unauthorized < FaunaError; end
  class PermissionDenied < FaunaError; end
  class NotFound < FaunaError; end
  class MethodNotAllowed < FaunaError; end
  class InternalError < FaunaError; end
  class UnavailableError < FaunaError; end
  class InvalidQuery < FaunaError; end
end
