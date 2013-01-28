require File.expand_path('../../test_helper', __FILE__)

# TODO use association_test classes

class TimelineTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class MessageBoard < Fauna::Class
    timeline :posts
  end

  class Post < Fauna::Class
    field :body
  end

  def setup
    super
    Fauna::TimelineSettings.create!("posts")
    MessageBoard.save!
    Post.save!
    @model = MessageBoard.create!
  end

  def test_page
    page = @model.posts.page
    assert_equal page.ref, "#{@model.ref}/timelines/posts"
    assert_equal page.events.size, 0
  end

  def test_timeline_add
    @model.posts.add(Post.create(:body => "hi"))
    page = @model.posts.page
    assert_equal page.events.size, 1
    assert_equal page.events[0].resource.body, "hi"
  end

  def test_timeline_remove
    @model.posts.add(Post.create(:body => "hi"))
    page = @model.posts.page
    assert_equal page.events.size, 1
    @model.posts.remove(page.events[0].resource)
  end
end
