module Fauna
  ##
  # Error for when the server returns an unexpected kind of response.
  class UnexpectedError < RuntimeError
    # RequestResult for the request that caused this error.
    attr_reader :request_result

    def initialize(description, request_result) # :nodoc:
      super(description)
      @request_result = request_result
    end

    def self.get_or_raise(request_result, hash, key) # :nodoc:
      unless hash.is_a? Hash and hash.key? key
        fail UnexpectedError.new("Response JSON does not contain expected key #{key}", request_result)
      end
      hash[key]
    end
  end

  ##
  # Error returned by the FaunaDB server.
  # For documentation of error types, see the docs[https://faunadb.com/documentation#errors].
  class FaunaError < RuntimeError
    # List of ErrorData objects returned by the server.
    attr_reader :errors

    # RequestResult for the request that caused this error.
    attr_reader :request_result

    ##
    # Raises the associated error from a RequestResult based on the status code.
    #
    # Returns +nil+ for 2xx status codes
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
        fail UnexpectedError.new('Unexpected status code.', request_result)
      end
    end

    # Creates a new error from a given RequestResult or Exception.
    def initialize(request_result)
      message = nil

      if request_result.is_a? RequestResult
        @request_result = request_result

        begin
          errors_raw = UnexpectedError.get_or_raise request_result, request_result.response_content, :errors
          @errors = catch :invalid_response do
            throw :invalid_response unless errors_raw.is_a? Array
            errors_raw.map { |error| ErrorData.from_hash(error) }
          end

          if @errors.nil?
            fail UnexpectedError.new('Error data has an unexpected format.', request_result)
          elsif @errors.empty?
            fail UnexpectedError.new('Error data returned was blank.', request_result)
          end

          message = @errors.map do |error|
            msg = 'Error'
            msg += " at #{error.position}" unless error.position.nil?
            msg += ": #{error.code} - #{error.description}"

            unless error.failures.nil?
              msg += ' (' + error.failures.map do |failure|
                "Failure at #{failure.field}: #{failure.code} - #{failure.description}"
              end.join(' ') + ')'
            end

            msg
          end.join(' ')
        rescue UnexpectedError => e
          if request_result.status_code != 503
            raise e
          end

          message = request_result.response_raw
        end
      elsif request_result.is_a? Exception
        message = request_result.class.name
        unless request_result.message.nil?
          message += ": #{request_result.message}"
        end
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

  # Data for one error returned by the server.
  class ErrorData
    ##
    # Error code.
    #
    # Reference: {FaunaDB Error codes}[https://faunadb.com/documentation#errors]
    attr_reader :code
    # Error description.
    attr_reader :description
    # Position of the error in a query. May be +nil+.
    attr_reader :position
    # List of Failure objects returned by the server. +nil+ except for <code>validation failed</code> errors.
    attr_reader :failures

    def self.from_hash(hash) # :nodoc:
      code = ErrorHelpers.get_or_throw hash, :code
      description = ErrorHelpers.get_or_throw hash, :description
      position = ErrorHelpers.map_position hash[:position]
      failures = hash[:failures].map(&Failure.method(:from_hash)) unless hash[:failures].nil?
      ErrorData.new code, description, position, failures
    end

    def initialize(code, description, position, failures) # :nodoc:
      @code = code
      @description = description
      @position = position
      @failures = failures
    end

    def inspect # :nodoc:
      "ErrorData(#{code.inspect}, #{description.inspect}, #{position.inspect}, #{failures.inspect})"
    end
  end

  ##
  # Part of ErrorData.
  # For more information, see the {docs}[https://faunadb.com/documentation#errors-invalid_data].
  class Failure
    # Failure code.
    attr_reader :code
    # Failure description.
    attr_reader :description
    # Field of the failure in the instance.
    attr_reader :field

    def self.from_hash(hash) # :nodoc:
      Failure.new(
        ErrorHelpers.get_or_throw(hash, :code),
        ErrorHelpers.get_or_throw(hash, :description),
        ErrorHelpers.map_position(hash[:field]),
      )
    end

    def initialize(code, description, field) # :nodoc:
      @code = code
      @description = description
      @field = field
    end

    def inspect # :nodoc:
      "Failure(#{code.inspect}, #{description.inspect}, #{field.inspect})"
    end
  end

  module ErrorHelpers # :nodoc:
    def self.map_position(position)
      unless position.nil?
        position.map do |part|
          if part.is_a? String
            part.to_sym
          else
            part
          end
        end
      end
    end

    def self.get_or_throw(hash, key)
      throw :invalid_response unless hash.is_a? Hash and hash.key? key
      hash[key]
    end
  end
end
