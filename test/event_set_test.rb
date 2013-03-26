require File.expand_path('../test_helper', __FILE__)

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

  # FIXME implement pagination with after & before

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

  def test_event_set_resources
    post = Post.create(:body => "Hello")
    @model.posts.add(post)
    assert_equal [post], @model.posts.resources
    assert_equal [post], @model.posts.creates.resources
    assert_equal [post], @model.posts.updates.resources
  end

  def test_event_set_query
    posts = (1..3).map do |i|
      Post.create(:body => "p#{i}").tap do |p|
        @model.posts.add(p)
      end
    end

    comments = posts.map do |p|
      (1..3).map do |i|
        Comment.create(:body => "#{p.body}_c#{i}").tap do |c|
          p.comments.add(c)
        end
      end
    end

    q = Fauna::EventSet.join(@model.posts, 'sets/comments')

    assert_equal 9, q.resources.size

    comments.flatten.each do |c|
      assert q.resources.include?(c)
    end
  end
end
