require File.expand_path('../test_helper', __FILE__)

# TODO use association_test classes

class QueryTest < MiniTest::Unit::TestCase

  def setup
    super
    @model = Fauna::Resource.create 'classes/message_boards'
    @posts_set = @model.set 'posts'
    @posts = []
    @comments = []

    3.times do |i|
      post = Fauna::Resource.create(
        'classes/posts',
        { :data =>
          { :topic => "The Horned King" } })
      @posts << post
      @posts_set.add(post)
      3.times do |j|
        comment = Fauna::Resource.create(
          'classes/comments',
          { :data =>
            { :text => "Do not show the Horned King the whereabouts of the Black Cauldron!" } })
        @comments << comment
        Fauna::CustomSet.new("#{post.ref}/sets/comments").add(comment)
      end
    end
  end

  def test_join
    query = Fauna::Set.join @posts_set, '_/sets/comments'
    assert_equal 9, query.page.size
    @comments.flatten.each do |comment|
      assert query.page.include? comment.ref
    end
  end

  def test_match
    query = Fauna::Set.match 'classes/posts', 'data.topic', 'The Horned King'
    assert query.page.size > 1
  end
end
