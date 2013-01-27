require File.expand_path('../../test_helper', __FILE__)

class AssociationsTest < MiniTest::Unit::TestCase
  class ::Post < Fauna::Class
    field :title, :body
    timeline :comments
  end

  class ::Comment < Fauna::Class
    field :body
    reference :post
  end

  def setup
    Fauna::TimelineSettings.create("comments")
  end

  def test_timeline
    post = comment = nil
    post = Post.create(:title => 'Hello World', :body => 'My first post')
    comment = Comment.create(:body => 'First!')
    post.comments.add(comment)
    assert_equal comment, post.comments.resources[0]
  end

  def test_reference
    post = comment = nil
    post = Post.create(:title => 'Hello World', :body => 'My first post')
    comment = Comment.create(:body => 'First!')
    comment.post = post
    comment.save
    assert_equal comment.post.ref, post.ref
    assert_equal comment.post_ref, post.ref
  end
end
