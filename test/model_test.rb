require File.expand_path('../test_helper', __FILE__)

require "fauna/model"

class ModelTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

    class Henwen < Fauna::Model
      data_attr :used
    end

  def setup
    @model = Henwen.new
  end

  def test_class_name
    assert_equal 'ModelTest::Henwen', Henwen.class_name
  end

  def test_class_setup
    assert_equal 'classes/ModelTest::Henwen', Henwen.ref
  end

  def test_initialize_with_params
    object = Henwen.new(:used => false)
    assert_equal object.used, false
    assert !object.ref
    assert object.new_record?
  end

  def test_create
      object = Henwen.create(:used => false)
      assert_equal object.used, false
      assert object.persisted?
      assert object.ref
  end

  def test_save
    object = Henwen.new(:used => false)
      object.save
      assert object.persisted?
  end

  def test_update
      object = Henwen.new(:used => false)
      object.save
        object.update(:used => true)
        assert object.used
  end

  def test_find
      object = Henwen.create(:used => false)
      ref = object.ref
      id = object.id
        object1 = Henwen.find(ref)
        object2 = Henwen.find(id)
        assert_equal object1.ref, object2.ref
        assert_equal ref, object1.ref
        assert object1.persisted?
  end

  def test_destroy
      object = Henwen.create(:used => false)
        object.destroy
        assert !object.ref
        assert object.destroyed?
        assert object.id
  end
end
