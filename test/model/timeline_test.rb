require File.expand_path('../../test_helper', __FILE__)

# TODO use association_test classes

class EventSetTest < ActiveModel::TestCase
  # include ActiveModel::Lint::Tests

  def setup
    super
    @model = MessageBoard.create!
  end

  def test_page
    page = @model.posts.page
    assert_equal page.ref, "#{@model.ref}/sets/posts"
    assert_equal page.events.size, 0
  end

  def test_any
    @model.posts.add(Post.create(:body => "Hello"))
    assert @model.posts.page.any?
    assert @model.posts.page.events.any?
  end

  def test_event_set_add
    @model.posts.add(Post.create(:body => "Goodbye"))
    page = @model.posts.page
    assert_equal page.events.size, 1
    assert_equal page.events[0].resource.body, "Goodbye"
  end

  def test_event_set_remove
    @model.posts.add(Post.create(:body => "Hello"))
    page = @model.posts.page
    assert_equal page.events.size, 1
    @model.posts.remove(page.events[0].resource)
  end
end
