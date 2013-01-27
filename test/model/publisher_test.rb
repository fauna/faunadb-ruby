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
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_save
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_update
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_find
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_destroy
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end
end
