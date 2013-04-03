module Fauna
  class Client

    class NoContextError < StandardError
    end

    class CachingContext
      attr_reader :connection

      def initialize(connection)
        raise ArgumentError, "Connection cannot be nil" unless connection
        @cache = {}
        @connection = connection
      end

      def get(ref, query = nil)
        if @cache[ref]
          Resource.alloc(@cache[ref])
        else
          res = @connection.get(ref, query)
          cohere(ref, res)
          Resource.alloc(res['resource'])
        end
      end

      def post(ref, data)
        res = @connection.post(ref, filter(data))
        cohere(ref, res)
        Resource.alloc(res['resource'])
      end

      def put(ref, data)
        res = @connection.put(ref, filter(data))
        cohere(ref, res)
        Resource.alloc(res['resource'])
      end

      def delete(ref, data)
        @connection.delete(ref, data)
        @cache.delete(ref)
        nil
      end

      private

      def filter(data)
        data.select {|_, v| v }
      end

      def cohere(ref, res)
        # FIXME Implement set range caching
        if (res['resource']['class'] != "sets")
          @cache[ref] = res['resource'] if ref =~ %r{^users/self}
          @cache[res['resource']['ref']] = res['resource']
          @cache.merge!(res['references'] || {})
        end
      end
    end

    def self.context(connection)
      push_context(connection)
      yield
    ensure
      pop_context
    end

    def self.push_context(connection)
      stack.push(CachingContext.new(connection))
    end

    def self.pop_context
      stack.pop
    end

    def self.get(ref, query = nil)
      this.get(ref, query)
    end

    def self.post(ref, data = nil)
      this.post(ref, data)
    end

    def self.put(ref, data = nil)
      this.put(ref, data)
    end

    def self.delete(ref, data = nil)
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
