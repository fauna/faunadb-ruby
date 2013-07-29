module Fauna
  class Client

    end

    end

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
      stack = []
    end

    def self.get(ref, query = {}, pagination = {})
      this.get(ref, query, pagination)
    end

    def self.post(ref, data = {})
      this.post(ref, data)
    end

    def self.put(ref, data = {})
      this.put(ref, data)
    end

    def self.delete(ref, data = {})
      this.delete(ref, data)
    end

    def self.this
      stack.last or raise NoContextError, "You must be within a Fauna::Client.context block to perform operations."
    end

    class << self
      private

      def stack
        Thread.current[:fauna_context_stack] ||= []
      end
    end
  end
end
