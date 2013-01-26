require File.expand_path('../../test_helper', __FILE__)

require "fauna/class"

class AssociationsTest < MiniTest::Unit::TestCase
  class ::Post < Fauna::Class
    data_attr :title, :body
    has_timeline :comments
  end

  class ::Comment < Fauna::Class
    data_attr :body
    reference :post
  end

  def setup
    Fauna::TimelineSettings.create("comments")
  end

  def test_has_timeline
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
