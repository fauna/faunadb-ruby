require File.expand_path('../test_helper', __FILE__)

require "fauna/model"

class AssociationsTest < MiniTest::Unit::TestCase
  stub_response(:get, fake_response(200, "OK", "post_model")) do
    class ::Post < Fauna::Model
      data_attr :title, :body
      has_timeline :comments
    end
  end

  stub_response(:get, fake_response(200, "OK", "comment_model")) do
    class ::Comment < Fauna::Model
      data_attr :body
      reference :post
    end
  end

  def setup
    stub_response(:put, fake_response(201, "Created", "timeline")) do
      Fauna::TimelineSettings.create("comments")
    end
  end

  def test_has_timeline
    post = comment = nil
    stub_response(:post, fake_response(201, "Created", "post_model_instance")) do
      post = Post.create(:title => 'Hello World', :body => 'My first post')
    end

    stub_response(:post, fake_response(201, "Created", "comment_model_instance")) do
      comment = Comment.create(:body => 'First!')
    end

    stub_response(:post, fake_response(201, "Created", "comments_timeline")) do
      stub_response(:get, fake_response(200, "OK", "comments_timeline")) do
        post.comments.add(comment)
      end
    end

    assert_equal comment, post.comments[comment.ref]
  end

  def test_reference
    post = comment = nil
    stub_response(:post, fake_response(201, "Created", "post_model_instance")) do
      post = Post.create(:title => 'Hello World', :body => 'My first post')
    end

    stub_response(:post, fake_response(201, "Created", "comment_model_instance")) do
      comment = Comment.create(:body => 'First!')
    end

    comment.post = post

    assert_equal comment.post.ref, post.ref
    assert_equal comment.post_ref, post.ref
  end
end

