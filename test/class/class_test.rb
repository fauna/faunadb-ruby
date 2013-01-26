require File.expand_path('../../test_helper', __FILE__)

class ClassTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class TestClass < Fauna::Class
    data_attr :used
  end

  def setup
    TestClass.class_name = "test_class"
    Fauna::Client.context(@publisher_connection) do
      TestClass.setup!
    end

    @class = TestClass.new
  end

  def test_class_name
    assert_equal 'ClassTest::TestClass', TestClass.class_name
  end

  def test_class_setup
    assert_equal 'classes/ClassTest::TestClass', TestClass.ref
  end

  def test_initialize_with_params
    object = TestClass.new(:used => false)
    assert_equal object.used, false
    assert !object.ref
    assert object.new_record?
  end

  def test_create
    object = TestClass.create(:used => false)
    assert_equal object.used, false
    assert object.persisted?
    assert object.ref
  end

  def test_save
    object = TestClass.new(:used => false)
    object.save
    assert object.persisted?
  end

  def test_update
    object = TestClass.new(:used => false)
    object.save
    object.update(:used => true)
    assert object.used
  end

  def test_find
    object = TestClass.create(:used => false)
    ref = object.ref
    id = object.id
    object1 = TestClass.find(ref)
    object2 = TestClass.find(id)
    assert_equal object1.ref, object2.ref
    assert_equal ref, object1.ref
    assert object1.persisted?
  end

  def test_destroy
    object = TestClass.create(:used => false)
    object.destroy
    assert !object.ref
    assert object.destroyed?
    assert object.id
  end
end
