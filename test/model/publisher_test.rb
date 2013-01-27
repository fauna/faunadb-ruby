require File.expand_path('../../test_helper', __FILE__)

class PublisherTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class Publisher < Fauna::Publisher
  end

  def setup
    super
    @model = Publisher.new
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
