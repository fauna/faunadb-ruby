module Fauna
  class Client
    def self.context(connection)
      push_context(connection)
      yield
    ensure
      pop_context
    end

    def self.push_context(connection)
      stack.push(Fauna::Cache.new(connection))
    end

    def self.pop_context
      stack.pop
    end

    def self.reset_context
      stack = [] # rubocop:disable Lint/UselessAssignment
    end

    def self.get(ref, query = {}, pagination = {})
      connection.get(ref, query, pagination)
    end

    def self.post(ref, data = {})
      connection.post(ref, data)
    end

    def self.put(ref, data = {})
      connection.put(ref, data)
    end

    def self.patch(ref, data = {})
      connection.patch(ref, data)
    end

    def self.delete(ref, data = {})
      connection.delete(ref, data)
    end

    def self.connection
      stack.last || fail(NoContextError, 'You must be within a Fauna::Client.context block to perform operations.')
    end

    class << self
    private

      def stack
        Thread.current[:fauna_context_stack] ||= []
      end
    end
  end
end
