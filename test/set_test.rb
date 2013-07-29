require File.expand_path('../test_helper', __FILE__)

# TODO use association_test classes

class SetTest < MiniTest::Unit::TestCase

  def setup
    super
    @model = MessageBoard.create
    @posts = Fauna::CustomSet.new("#{@model.ref}/sets/posts")
  end

  def test_page
    page = @posts.page
    assert_equal "#{@model.ref}/sets/posts", page.ref
    assert_equal 0, page.refs.size
  end

  def test_pagination
    @posts.add(Post.create)
    @posts.add(Post.create)
    @posts.add(Post.create)
    @posts.add(Post.create)
    @posts.add(Post.create)

    page1 = @posts.page(:size => 2)
    assert_equal 2, page1.refs.size
    page2 = @posts.page(:size => 2, :before => page1.before)
    assert_equal 2, page2.refs.size
    page3 = @posts.page(:size => 2, :before => page2.before)
    assert_equal 1, page3.refs.size

    page4 = @posts.page(:size => 2, :after => page3.refs.last)
    assert_equal 2, page4.refs.size
    page5 = @posts.page(:size => 2, :after => page4.after)
    assert_equal 2, page5.refs.size
    page6 = @posts.page(:size => 2, :after => page5.refs.first)
    assert_equal 1, page6.refs.size
  end

  def test_any
    @posts.add(Post.create)
    assert @posts.page.any?
    assert @posts.page.refs.any?
    assert @posts.events.any?
    assert @posts.events.events.any?
  end

  def test_event_set_add
    post = Post.create
    @posts.add(post)
    page = @posts.page
    assert_equal 1, page.refs.size
    assert_equal post.ref, page.refs[0]
  end

  def test_event_set_remove
    @posts.add(Post.create)
    page = @posts.page
    assert_equal 1, page.refs.size
    @posts.remove(page.refs[0])
  end

  def test_event_set_refs
    post = Post.create
    @posts.add(post)
    assert_equal [post.ref], @posts.page.refs
  end

  def test_event_set_query
    posts = (1..3).map do |i|
      Post.create.tap do |p|
        @posts.add(p)
      end
    end

    comments = posts.map do |p|
      (1..3).map do |i|
        Comment.create.tap do |c|
          comments = Fauna::CustomSet.new("#{p.ref}/sets/comments")
          comments.add(c)
        end
      end
    end

    q = Fauna::Set.join(@posts, 'sets/comments')

    assert_equal 9, q.page.size

    comments.flatten.each do |c|
      assert q.page.include?(c.ref)
    end
  end
end
