module Fauna
  class Client

    class NoContextError < StandardError
    end

    class Resource < OpenStruct
      def to_hash
        @table
      end

      def merge(resource)
        to_hash.merge(resource.to_hash)
      end
    end

    class CachingContext
      attr_reader :connection

      def initialize(connection)
        raise ArgumentError, "Connection cannot be nil" unless connection
        @cache = {}
        @connection = connection
      end

      def get(ref)
        if @cache[ref]
          Resource.new(@cache[ref])
        else
          res = @connection.get(ref)
          cohere(res)
          Resource.new(res['resource'])
        end
      end

      def post(ref, data)
        res = @connection.post(ref, filter(data))
        cohere(res)
        Resource.new(res['resource'])
      end

      def put(ref, data)
        res = @connection.put(ref, filter(data))
        cohere(res)
        Resource.new(res['resource'])
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

      def cohere(res)
        @cache[res['resource']['ref']] = res['resource']
        @cache.merge!(res['references'])
      end
    end

    class << self
      def context(connection)
        stack.push(CachingContext.new(connection))
        yield
      ensure
        stack.pop
      end

      def get(ref)
        this.get(ref)
      end

      def post(ref, data = nil)
        this.post(ref, data)
      end

      def put(ref, data = nil)
        this.put(ref, data)
      end

      def delete(ref, data = nil)
        this.delete(ref, data)
      end

      def this
        stack.last or raise NoContextError, "You must be within a Fauna::Client.context block to perform operations."
      end

      private

      def stack
        Thread.current[:fauna_context_stack] ||= []
      end
    end
  end
end
