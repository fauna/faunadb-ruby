require File.expand_path('../../test_helper', __FILE__)

class ClassTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class TestClass < Fauna::Class
    field :visited
  end

  def setup
    super
    Fauna::Client.context(@publisher_connection) do
      TestClass.save!
    end
  end

  def test_class_name
    assert_equal 'classes/test_class', TestClass.ref
  end

  def test_class_save
    Fauna::Client.context(@publisher_connection) do
      TestClass.data["class_visited"] = true
      TestClass.save!
      TestClass.reload!
    end
    assert TestClass.data["class_visited"]
  end

  def test_create
    object = TestClass.create(:visited => false)
    assert_equal object.visited, false
    assert object.persisted?
    assert object.ref
  end

  def test_save
    object = TestClass.new(:visited => false)
    object.save
    assert object.persisted?
  end

  def test_update
    object = TestClass.new(:visited => false)
    object.save
    object.update(:visited => true)
    assert object.visited
  end

  def test_find
    object = TestClass.create(:visited => false)
    ref = object.ref
    id = object.id
    object1 = TestClass.find(ref)
    object2 = TestClass.find(id)
    assert_equal object1.ref, object2.ref
    assert_equal ref, object1.ref
    assert object1.persisted?
  end

  def test_destroy
    object = TestClass.create(:visited => false)
    object.destroy
    assert !object.ref
    assert object.destroyed?
    assert object.id
  end
end
