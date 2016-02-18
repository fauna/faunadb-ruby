module Fauna
  class Page
    # Always an Array. Element type may vary.
    attr_reader :data
    # Nilable cursor for the previous page.
    attr_reader :before
    # Nilable cursor for the next page.
    attr_reader :after

    # Convert a raw response hash to a Page.
    def self.from_hash(hash)
      Page.new hash[:data], hash[:before], hash[:after]
    end

    def initialize(data, before = nil, after = nil)
      @data = data
      @before = before
      @after = after
    end

    # Return a new Page whose data has had block applied to each element.
    def map_data(&block)
      Page.new data.map(&block), before, after
    end

    def to_s
      "Page(#{data}, #{before}, #{after})"
    end

    def ==(other)
      return false unless other.is_a? Page
      data == other.data && before == other.before && after == other.after
    end

    alias_method :eql?, :==

    # Like set_iterator but enumerates over pages rather than their content.
    def self.page_iterator(client, set_query, params = {})
      PageIter.new(client, set_query, params).to_enum
    end

    ##
    # Enumerable that keeps getting new values in a set through pagination.
    # For example:
    #
    #   iter = Page.set_iterator client, set_query, map: (Query.expr do
    #     lambda do |ref|
    #       select [:data], get(ref)
    #     end
    #   end)
    #   puts iter.to_a
    #
    # +client+:: A Client.
    # +set_query+:: Set query to paginate, such as Query.match.
    # +params+:: All optional.
    #            +:map+:: Query.lambda for mapping set elements.
    #            +:page_size+:: Number of instances to be fetched per page.
    def self.set_iterator(client, set_query, params = {})
      page_iterator(client, set_query, params).flat_map &:data
    end
  end

private

  class PageIter # :nodoc:
    def initialize(client, set_query, params)
      @client = client
      @set_query = set_query
      @map = params[:map]
      @page_size = params[:page_size]
    end

    def each
      page = get_page
      yield page
      next_cursor_kind = page.after.nil? ? :before : :after

      next_cursor = page.send next_cursor_kind
      until next_cursor.nil?
        page = get_page next_cursor_kind => next_cursor
        yield page
        next_cursor = page.send next_cursor_kind
      end
    end

  private

    def get_page(params = {})
      page = @client.query do
        params[:size] = @page_size unless @page_size.nil?
        queried = paginate @set_query, params
        queried = map queried, @map unless @map.nil?
        queried
      end
      Page.from_hash page
    end
  end
end
