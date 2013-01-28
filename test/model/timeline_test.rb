require File.expand_path('../../test_helper', __FILE__)

class TimelineTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class MessageBoard < Fauna::Class
    timeline :followers
  end

  def setup
    super
    MessageBoard.save!
    @model = MessageBoard.create!
  end

  def test_page
    p @model.followers.page

  end

  def test_save
    fail
  end

  def test_update
    fail
  end

  def test_find
    fail
  end

  def test_destroy
    fail
  end
end
