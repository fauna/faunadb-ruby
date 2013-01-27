require File.expand_path('../../test_helper', __FILE__)

class ClassTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class Pigkeeper < Fauna::Class
    field :visited
  end

  def setup
    super
    Fauna::Client.context(@publisher_connection) do
      Pigkeeper.save!
    end
    @model = Pigkeeper.new
  end

  def test_class_name
    assert_equal 'classes/test_class', Pigkeeper.ref
  end

  def test_class_save
    Fauna::Client.context(@publisher_connection) do
      Pigkeeper.data["class_visited"] = true
      Pigkeeper.save!
      Pigkeeper.reload!
    end
    assert Pigkeeper.data["class_visited"]
  end

  def test_create
    Fauna::Client.context(@publisher_connection) do
      object = Pigkeeper.create(:visited => false)
      assert_equal false, object.visited
      assert object.persisted?
      assert object.ref
    end
  end

  def test_save
    Fauna::Client.context(@publisher_connection) do
      object = Pigkeeper.new(:visited => false)
      object.save
      assert object.persisted?
    end
  end

  def test_update
    Fauna::Client.context(@publisher_connection) do
      object = Pigkeeper.new(:visited => false)
      object.save
      object.update(:visited => true)
      assert object.visited
    end
  end

  def test_find
    Fauna::Client.context(@publisher_connection) do
      object = Pigkeeper.create(:visited => false)
      object1 = Pigkeeper.find(object.ref)
      assert_equal object.ref, object1.ref
      assert object1.persisted?
    end
  end

  def test_destroy
    Fauna::Client.context(@publisher_connection) do
      object = Pigkeeper.create(:visited => false)
      object.destroy
      assert object.destroyed?
    end
  end
end
