module Fauna
  ##
  # Helper for handling pagination over sets.
  #
  # Given a client and a set, allows you to iterate as well as individually move page by page over a set.
  #
  # The initial page created will always be unpopulated. Unpopulated pages will contain no data, and the first
  # page returned will be the one dictated by the configured cursor, regardless of the direction being paged in.
  # Subsequent pages will proceed in the requested direction. Page instances created by builders will always
  # reset paging and return an initial, unpopulated page.
  #
  # Explicit paging is done via the +next+ and +prev+ methods. Iteration can be done via the +each+ and
  # +reverse_each+ enumerators. A single page can be retrieved by passing a cursor and then calling either +next+
  # or +prev+.
  #
  # Examples:
  #
  # Paging over a class index
  #
  #   page = Page.new(client, Query.match(Ref('indexes/items')))
  #
  # Paging over a class index 5 at a time, mapping the refs to the +data.value+ for each instance
  #
  #   page = Page.new(client, Query.match(Ref('indexes/items')), size: 5) do |page|
  #     map(page) { |ref| select ['data', 'value'], get(ref) }
  #   end
  #
  #   # Same thing, but using builders instead
  #
  #   page = Page.new(client, Query.match(Ref('indexes/items'))).with_size(5).with_fauna_map do |page|
  #     map(page) { |ref| select ['data', 'value'], get(ref) }
  #   end
  class Page
    ##
    # Creates a pagination helper for paging/iterating over a set.
    #
    # +client+:: Client to execute queries with.
    # +set+:: A set query to paginate over.
    # +params+:: A list of parameters to pass to {paginate}[https://faunadb.com/documentation/queries#read_functions-paginate_set].
    # +fauna_map+:: Optional block to wrap the generated paginate query with. The block will be run in a query context.
    #               The paginate query will be passed into the block as an argument.
    def initialize(client, set, params = {}, &fauna_map)
      @client = client
      @set_query = set
      @page_params = params
      @fauna_map = fauna_map
      @ruby_map = nil

      unload_page
    end

    ##
    # Data contained within the current page.
    #
    # Always +nil+ for the initial page. Call one of the pagination methods to begin paging.
    attr_reader :data

    ##
    # Before cursor for the current page.
    #
    # Always +nil+ for the initial page. Call one of the pagination methods to begin paging.
    attr_reader :before

    ##
    # After cursor for the current page.
    #
    # Always +nil+ for the initial page. Call one of the pagination methods to begin paging.
    attr_reader :after

    # Returns +true+ if +other+ is a Page and contains the same configuration and data.
    def ==(other)
      return false unless other.is_a? Page
      data == other.data && before == other.before && after == other.after &&
          @initial == other.instance_variable_get(:@initial) &&
          @client == other.instance_variable_get(:@client) &&
          @set_query == other.instance_variable_get(:@set_query) &&
          @page_params == other.instance_variable_get(:@page_params) &&
          @fauna_map == other.instance_variable_get(:@fauna_map) &&
          @ruby_map == other.instance_variable_get(:@ruby_map)
    end

    alias_method :eql?, :==

    # :section: Builders

    ##
    # Returns a copy of the page with the given +ts+ set.
    #
    # See {paginate}[https://faunadb.com/documentation/queries#read_functions-paginate_set] for more details.
    def with_ts(ts)
      with_dup do |page|
        page.instance_variable_get(:@page_params)[:ts] = ts
      end
    end

    ##
    # Returns a copy of the page with the given cursor set.
    #
    # Cursors either contain a +before+ or +after+ parameter.
    #
    # See {paginate}[https://faunadb.com/documentation/queries#read_functions-paginate_set] for more details.
    def with_cursor(cursor = {})
      with_dup do |page|
        page.send(:load_cursor, cursor)
      end
    end

    ##
    # Returns a copy of the page with the given +size+ set.
    #
    # See {paginate}[https://faunadb.com/documentation/queries#read_functions-paginate_set] for more details.
    def with_size(size = nil)
      with_dup do |page|
        page.instance_variable_get(:@page_params)[:size] = size
      end
    end

    ##
    # Returns a copy of the page with the given +events+ set.
    #
    # See {paginate}[https://faunadb.com/documentation/queries#read_functions-paginate_set] for more details.
    def with_events(events)
      with_dup do |page|
        page.instance_variable_get(:@page_params)[:events] = events
      end
    end

    ##
    # Returns a copy of the page with the given +sources+ set.
    #
    # See {paginate}[https://faunadb.com/documentation/queries#read_functions-paginate_set] for more details.
    def with_sources(sources)
      with_dup do |page|
        page.instance_variable_get(:@page_params)[:sources] = sources
      end
    end

    ##
    # Returns a copy of the page with the given fauna block set.
    #
    # The block, when provided, will be used to wrap the generated paginate query with a fauna query.
    # The block will be run in a Query.expr context, and passed the generated paginate query as a parameter.
    #
    # Example of mapping a set of refs to their instances:
    #
    #   page.with_fauna_map { |page_q| map(page_q) { |ref| get ref } }
    def with_fauna_map(&block)
      with_dup do |page|
        page.instance_variable_set(:@fauna_map, block)
      end
    end

    ##
    # Returns a copy of the page with the given ruby block set.
    #
    # The block, when provided, will be used to map the returned data elements from the executed query.
    # The block will be passed the each element as a parameter from the data of the page currently being loaded.
    #
    # Example of loading instances into your own model:
    #
    #   page.with_ruby_map { |instance| YourModel.load(instance) }
    def with_ruby_map(&block)
      with_dup do |page|
        page.instance_variable_set(:@ruby_map, block)
      end
    end

    # :section: Pagination

    ##
    # The next page in the set.
    #
    # Initial, unpopulated pages will return the first page from the set with the configured cursor.
    # Following pages will page over the +after+ cursor until the end of the set is reached.
    # Returns +nil+ when there are no more pages after the current page.
    def next
      new_page(:after)
    end

    ##
    # The previous page in the set.
    #
    # Initial, unpopulated pages will return the first page from the set with the configured cursor.
    # Following pages will page over the +before+ cursor until the end of the set is reached.
    # Returns +nil+ when there are no more pages before the current page.
    def prev
      new_page(:before)
    end

    ##
    # Returns an enumerator that iterates in the +after+ direction.
    #
    # When a block is provided, the return of the block will always be +nil+ (to avoid loading large sets into memory).
    def each
      return enum_for(:each) unless block_given?

      page = self.next

      until page.nil?
        yield page.data
        page = page.next
      end
    end

    ##
    # Returns an enumerator that iterates in the +before+ direction.
    #
    # When a block is provided, the return of the block will always be +nil+ (to avoid loading large sets into memory).
    #
    # While the paging will occur in the reverse direction, the data returned will still be in the normal direction.
    def reverse_each
      return enum_for(:reverse_each) unless block_given?

      page = self.prev

      until page.nil?
        yield page.data
        page = page.prev
      end
    end

    def dup # :nodoc:
      page = super
      page.instance_variable_set(:@page_params, @page_params.dup)
      page
    end

  private

    CURSOR_KEYS = [:before, :after] # :nodoc:

    def with_dup
      # Create a copy and drop loaded data
      page = self.dup
      page.send(:unload_page)

      # Yield page for manipulation
      yield page

      # Return page
      page
    end

    def get_page(cursor = {})
      # Get pagination parameters
      if cursor.empty?
        params = @page_params
      else
        # Remove and replace existing cursor with passed cursor
        params = @page_params.select { |key, _| !CURSOR_KEYS.include?(key) }.merge(cursor)
      end

      # Create query
      query = Query.paginate @set_query, params

      unless @fauna_map.nil?
        # Wrap paginate query with the fauna block
        dsl = Query::QueryDSLContext.new
        query = Query::Expr.wrap DSLContext.eval_dsl(dsl, query, &@fauna_map)
      end

      # Execute query
      result = @client.query query

      unless @ruby_map.nil?
        # Map the resulting data with the ruby block
        result[:data].map! { |element| @ruby_map.call(element) }
      end

      result
    end

    def load_cursor(cursor = {})
      CURSOR_KEYS.each do |key, _|
        if cursor.include? key
          @page_params[key] = cursor[key]
        else
          @page_params.delete key
        end
      end
    end

    def load_page(page)
      # Not initial after the first page
      @initial = false

      # Update the page fields
      @data = page[:data]
      @before = page[:before]
      @after = page[:after]

      # Update the paging parameters
      load_cursor(page)
    end

    def unload_page
      # Reset paging
      @initial = true

      # Reset data
      @data = nil
      @before = nil
      @after = nil
    end

    def new_page(direction)
      fail "Invalid direction; must be one of #{CURSOR_KEYS}" unless CURSOR_KEYS.include?(direction)

      if CURSOR_KEYS.all? { |key| @page_params.include? key }
        # Ensure someone didn't try to start off with a cursor containing both a before and after.
        fail 'Only one cursor can be configured at a time' if @initial

        # Found cursors in both directions, select the one for our direction
        cursor = { direction => @page_params[direction] }
      else
        # Cursor for only one direction. This is either the first or last page.

        # If this is not the first page and there is no next cursor,
        # we have reached the end of the set. Return +nil+.
        return nil unless @initial || @page_params.include?(direction)

        # Use the already configured cursor to fetch the first page.
        cursor = {}
      end

      result = get_page(cursor)

      with_dup do |page|
        page.send(:load_page, result)
      end
    end
  end
end
