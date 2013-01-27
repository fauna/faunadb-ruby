require File.expand_path('../../test_helper', __FILE__)

class TimelineTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  def setup
    super
    @model = Fauna::Timeline.new
  end

  # def test_class_name
  #   assert_equal 'users', User.ref
  # end

  def test_create
    fail
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
