require File.expand_path('../test_helper', __FILE__)

# TODO use association_test classes

class SetTest < ActiveModel::TestCase
  # include ActiveModel::Lint::Tests

  def setup
    super
    @model = MessageBoard.create!
  end

  def test_page
    page = @model.posts.page
    assert_equal "#{@model.ref}/sets/posts", page.ref
    assert_equal 0, page.events.size
  end

  def test_pagination
    @model.posts.add(Post.create(:body => "Flewdyr Flam, called also Flewdyr Wledig."))
    @model.posts.add(Post.create(:body => "Recorded in the Triads as one of the three sovereigns."))
    @model.posts.add(Post.create(:body => "They preferred remaining as knights in the court of Arthur."))
    @model.posts.add(Post.create(:body => "Even so, they had dominions of their own."))
    @model.posts.add(Post.create(:body => "He is mentioned in the Mabinogi of Cilhwch and Olwen."))

    page1 = @model.posts.page(:size => 2)
    assert_equal 2, page1.events.size
    page2 = @model.posts.page(:size => 2, :before => page1.before)
    assert_equal 2, page2.events.size
    page3 = @model.posts.page(:size => 2, :before => page2.before)
    assert_equal 1, page3.events.size

    page4 = @model.posts.page(:size => 2, :after => page3.events.last.ts)
    assert_equal 2, page4.events.size
    page5 = @model.posts.page(:size => 2, :after => page4.after)
    assert_equal 2, page5.events.size
    page6 = @model.posts.page(:size => 2, :after => page5.after)
    assert_equal 1, page6.events.size
  end

  def test_any
    @model.posts.add(Post.create(:body => "Hello"))
    assert @model.posts.page.any?
    assert @model.posts.page.events.any?
  end

  def test_event_set_add
    @model.posts.add(Post.create(:body => "Goodbye"))
    page = @model.posts.page
    assert_equal 1, page.events.size
    assert_equal "Goodbye", page.events[0].resource.body
  end

  def test_event_set_remove
    @model.posts.add(Post.create(:body => "Hello"))
    page = @model.posts.page
    assert_equal 1, page.events.size
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

    q = Fauna::Set.join(@model.posts, 'sets/comments')

    assert_equal 9, q.resources.size

    comments.flatten.each do |c|
      assert q.resources.include?(c)
    end
  end
end
