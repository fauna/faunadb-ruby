module Fauna
  ##
  # Error raised when the context is used without a client being set.
  class NoContextError < RuntimeError; end

  ##
  # The client context wrapper.
  #
  # Used for accessing the client without directly passing around the client instance.
  # Context is scoped to the current thread.
  class Context
    ##
    # Returns a context block with the given client.
    #
    # +client+:: Client to use for the context block.
    def self.block(client)
      push(client)
      yield
    ensure
      pop
    end

    ##
    # Adds a client to the current context.
    #
    # +client+:: Client to add to the current context.
    def self.push(client)
      stack.push(client)
    end

    ##
    # Removes the last client context from the stack and returns it.
    def self.pop
      stack.pop
    end

    ##
    # Resets the current client context, removing all the clients from the stack.
    def self.reset
      stack.clear
    end

    ##
    # Issues a query to FaunaDB with the current client context.
    #
    # Queries are built via the Query helpers. See {FaunaDB Query API}[https://fauna.com/documentation/queries]
    # for information on constructing queries.
    #
    # +expression+:: A query expression
    #
    # :category: Client Methods
    def self.query(expression = nil, &expr_block)
      client.query(expression, &expr_block)
    end

    ##
    # Creates a Fauna::Page for paging/iterating over a set with the current client context.
    #
    # +set+:: A set query to paginate over.
    # +params+:: A list of parameters to pass to {paginate}[https://fauna.com/documentation/queries#read_functions-paginate_set].
    # +fauna_map+:: Optional block to wrap the generated paginate query with. The block will be run in a query context.
    #               The paginate query will be passed into the block as an argument.
    def self.paginate(set, params = {}, &fauna_map)
      client.paginate(set, params, &fauna_map)
    end

    ##
    # Returns the current context's client, or if there is none, raises NoContextError.
    def self.client
      stack.last || fail(NoContextError, 'You must be within a Fauna::Context.block to perform operations.')
    end

    class << self
    private

      def stack
        Thread.current[:fauna_context_stack] ||= []
      end
    end
  end
end
