require File.expand_path('../test_helper', __FILE__)

class PageTest < FaunaTest

  Items = Query.ref('classes/items')
  AllItems = Query.ref('indexes/all_items')

  def setup
    super

    client.query { create Items.to_class, name: Items.id }

    client.query do
      create AllItems.to_class,
             name: AllItems.id,
             source: Items,
             active: true
    end

    creates = (1..3).collect { |x| Query.create(Items, data: { value: x }) }
    @instances = client.query(creates)
    @instance_refs = @instances.map { |instance| instance[:ref] }
  end

  def test_builder
    # Test ts
    page = Page.new(client, Query.match(AllItems), ts: 1234)
    assert_equal 0, get_param(page.with_ts(0), :ts)
    assert_equal 1234, get_param(page, :ts)

    # Test cursor
    page = Page.new(client, Query.match(AllItems), before: 1)
    assert_equal({ before: 2 }, get_cursor(page.with_cursor(before: 2)))
    assert_equal({ before: 1 }, get_cursor(page))
    # Test cursor replace
    page = Page.new(client, Query.match(AllItems), before: 1)
    assert_equal({ after: 2 }, get_cursor(page.with_cursor(after: 2)))
    assert_equal({ before: 1 }, get_cursor(page))
    # Test cursor nil
    page = Page.new(client, Query.match(AllItems), after: nil)
    assert_equal({ before: nil }, get_cursor(page.with_cursor(before: nil)))
    assert_equal({ after: nil }, get_cursor(page))

    # Test size
    page = Page.new(client, Query.match(AllItems), size: 5)
    assert_equal 10, get_param(page.with_size(10), :size)
    assert_equal 5, get_param(page, :size)

    # Test events
    page = Page.new(client, Query.match(AllItems), events: true)
    assert_equal false, get_param(page.with_events(false), :events)
    assert_equal true, get_param(page, :events)

    # Test sources
    page = Page.new(client, Query.match(AllItems), sources: true)
    assert_equal false, get_param(page.with_sources(false), :sources)
    assert_equal true, get_param(page, :sources)

    # Test map
    page = Page.new(client, Query.match(AllItems))
    refute_equal get_block(page), get_block(page.with_map { |paginate| map(paginate) { |ref| get ref } })
  end

  def test_initial_page
    page = Page.new(client, Query.match(AllItems), size: 1, before: [@instance_refs[2]])
    assert_equal [@instance_refs[1]], page.data
    assert_equal [@instance_refs[1]], page.before
    assert_equal [@instance_refs[2]], page.after
  end

  def test_next
    # Initial page
    page = Page.new(client, Query.match(AllItems), size: 1, after: 0)
    assert_equal @instance_refs[0], page.next.data.first

    # Second page
    page = Page.new(client, Query.match(AllItems), size: 1, after: 0)
    page.data
    assert_equal @instance_refs[1], page.next.data.first
  end

  def test_prev
    # Initial page
    page = Page.new(client, Query.match(AllItems), size: 1, before: nil)
    assert_equal @instance_refs[2], page.prev.data.first

    # Second page
    page = Page.new(client, Query.match(AllItems), size: 1, before: nil)
    page.data
    assert_equal @instance_refs[1], page.prev.data.first
  end

  def test_each
    page = Page.new(client, Query.match(AllItems), size: 1)

    assert_equal @instance_refs.collect { |ref| [ref] }, page.each.collect { |ref| ref }
  end

  def test_reverse_each
    page = Page.new(client, Query.match(AllItems), size: 1, before: nil)

    assert_equal @instance_refs.reverse.collect { |ref| [ref] }, page.reverse_each.collect { |ref| ref }
  end

  def test_map_block
    page = Page.new(client, Query.match(AllItems), size: 1) { |page| map(page) { |ref| get(ref) } }

    assert_equal @instances.collect { |inst| [inst] }, page.each.collect { |inst| inst }
  end

private

  def get_param(page, field)
    page.instance_variable_get(:@page_params)[field]
  end

  def get_cursor(page)
    page.instance_variable_get(:@page_params).select { |key, _| [:before, :after].include? key }
  end

  def get_block(page)
    page.instance_variable_get(:@mapping_block)
  end
end
