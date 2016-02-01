module Fauna
  ##
  # Helper for handling pagination over sets.
  #
  # Given a client and a set, allows you to both individually move page by page and also iterate over a set.
  # Explicit paging is done via the +next+ and +prev+ methods. Iteration can be done via the +each+ and
  # +reverse_each+ enumerators. A single page can be retrieved by simply passing a cursor when creating the page.
  #
  # Examples:
  #
  # Paging over a class index
  #
  #   page = Page.new(client, Query.match(Ref('indexes/items')))
  #
  # Paging over a class index 5 at a time, and mapping the refs to the +data.value+ for each instance
  #
  #   page = Page.new(client, Query.match(Ref('indexes/items')), size: 5) do |page|
  #     map(page) { |ref| select ['data', 'value'], get(ref) }
  #   end
  #
  # You can also create a page via builder methods:
  #
  #   page = Page.new(client, Query.match(Ref('indexes/items'))).with_size(5).with_map do |page|
  #     map(page) { |ref| select ['data', 'value'], get(ref) }
  #   end
  class Page
    ##
    # Creates a pagination helper for paging/iterating over a set.
    #
    # +client+:: Client to execute queries with.
    # +set+:: A set query to paginate over.
    # +params+:: A list of parameters to pass to {paginate}[https://faunadb.com/documentation/queries#read_functions-paginate_set].
    # +map_block+:: Optional block to wrap the generated paginate query with. The block will be run in a query context.
    #               The paginate query will be passed into the block as an argument.
    def initialize(client, set, params = {}, &map_block)
      @loaded = false
      @data = nil
      @before = nil
      @after = nil

      @client = client
      @set_query = set
      @page_params = params
      @mapping_block = map_block
    end

    ##
    # Data contained within the current page.
    #
    # The current page is loaded on first access if not already loaded.
    def data
      load_page(get_page, true) unless @loaded
      @data
    end

    ##
    # Before cursor for the current page.
    #
    # The current page is loaded on first access if not already loaded.
    def before
      load_page(get_page, true) unless @loaded
      @before
    end

    ##
    # After cursor for the current page.
    #
    # The current page is loaded on first access if not already loaded.
    def after
      load_page(get_page, true) unless @loaded
      @after
    end

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
        params = page.instance_variable_get(:@page_params)
        CURSOR_KEYS.each do |key|
          if cursor.key? key
            params[key] = cursor[key]
          else
            params.delete key
          end
        end
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
    # Returns a copy of the page with the given mapping block set.
    #
    # The block, when provided, will be used to wrap the paginate query with a mapping query.
    # The block will be run in a Query.expr context, and passed the generated paginate query as a parameter.
    #
    # Example of mapping a set of refs to their instances
    #
    #   page.with_map { |page| map(page) { |ref| get ref } }
    #
    # See {Collection Functions}[https://faunadb.com/documentation/queries#collection_functions] for more details.
    def with_map(&block)
      with_dup do |page|
        page.instance_variable_set(:@mapping_block, block)
      end
    end

    # :section: Pagination

    ##
    # The next page in the set.
    #
    # Returns +nil+ if there is no next page.
    def next
      new_page(after: after) unless after.nil?
    end

    ##
    # The previous page in the set.
    #
    # Returns +nil+ if there is no previous page.
    def prev
      new_page(before: before) unless before.nil?
    end

    ##
    # Returns an enumerator that iterates in the +after+ direction.
    #
    # When a block is provided, the return of the block will always be +nil+ (in case the set is large).
    def each
      return enum_for(:each) unless block_given?

      page = new_page

      until page.nil?
        yield page.data
        page = page.next
      end
    end

    ##
    # Returns an enumerator that iterates in the +before+ direction.
    #
    # When a block is provided, the return of the block will always be +nil+ (in case the set is large).
    # While the paging will occur in the reverse direction, the data returned will still be in the normal direction.
    def reverse_each
      return enum_for(:reverse_each) unless block_given?

      page = new_page

      until page.nil?
        yield page.data
        page = page.prev
      end
    end

    # :nodoc:
    def dup
      page = super
      page.instance_variable_set(:@page_params, @page_params.dup)
      page
    end

  private

    CURSOR_KEYS = [:before, :after]

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
      if cursor.any? { |key, _| CURSOR_KEYS.include? key }
        # Remove and replace existing cursor with passed cursor
        params = @page_params.select { |key, _| !CURSOR_KEYS.include?(key) }.merge(cursor)
      else
        params = @page_params
      end

      # Create query
      query = Query.paginate @set_query, params

      unless @mapping_block.nil?
        # Wrap paginate query with mapping block
        dsl = Query::QueryDSLContext.new
        query = Query::Expr.wrap DSLContext.eval_dsl(dsl, query, &@mapping_block)
      end

      # Execute query
      @client.query query
    end

    def load_page(page, preserve = false)
      @loaded = true

      # Update the page fields
      @data = page[:data]
      @before = page[:before]
      @after = page[:after]

      return unless preserve

      # Update the paging parameters
      @page_params[:before] = @before
      @page_params[:after] = @after
    end

    def unload_page
      @loaded = false

      @data = nil
      @before = nil
      @after = nil
    end

    def new_page(cursor = {})
      result = get_page(cursor)

      with_dup do |page|
        page.send(:load_page, result)
      end
    end
  end
end
