require File.expand_path('../test_helper', __FILE__)

class PageTest < FaunaTest
  def setup
    super

    @class_ref = client.post('classes', name: 'gadgets')[:ref]
    index_ref = client.post('indexes',
      name: 'gadgets_by_n',
      source: @class_ref,
      path: 'data.n',
      active: true)[:ref]

    @a = create 0
    create 1
    @b = create 0

    @gadgets_set = Fauna::Query.expr { match index_ref, 0 }
  end

  def create(n)
    client.query { create @class_ref, data: { n: n } }[:ref]
  end

  def test_from_hash
    assert_equal Page.new(1, 2, 3), Page.from_hash(data: 1, before: 2, after: 3)
  end

  def test_map_data
    assert_equal Page.new([2, 3, 4], 2, 3), (Page.new([1, 2, 3], 2, 3).map_data do |x|
      x + 1
    end)
  end

  def test_page_iterator
    iter = Page.page_iterator client, @gadgets_set, page_size: 1
    assert_equal [[@a], [@b]], iter.to_a.map(&:data)
  end

  def test_set_iterator
    iter = Page.set_iterator client, @gadgets_set, page_size: 1
    assert_equal [@a, @b], iter.to_a
  end

  def test_mapper
    iter = Page.set_iterator client, @gadgets_set, map: (Query.expr do
      lambda do |ref|
        select [:data, :n], get(ref)
      end
    end)
    assert_equal [0, 0], iter.to_a
  end
end
