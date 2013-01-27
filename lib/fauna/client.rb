
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

    def self.context(connection)
      @stack ||= {}
      @stack[Thread.current] ||= []
      @stack[Thread.current].push(CachingContext.new(connection))
      yield
      @stack[Thread.current].pop
    end

    def self.get(ref)
      this.get(ref)
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
      @stack[Thread.current].last or raise NoContextError, "You must be within a Fauna::Client.context block to perform operations."
    end
  end
end
