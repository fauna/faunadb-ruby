require File.expand_path('../test_helper', __FILE__)

require "fauna/model"

class ModelTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  stub_response(:put, fake_response(200, "OK", "class_model")) do
    class Henwen < Fauna::Model
      data_attr :used
    end
  end

  def setup
    @model = Henwen.new
  end

  def teardown
    stub_response(:delete, fake_response(200, "OK", nil)) do
      Fauna::Class.delete("classes/ModelTest::Henwen")
    end
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
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object = Henwen.create(:used => false)

      assert_equal object.used, false
      assert object.persisted?
      assert object.ref
    end
  end

  def test_save
    object = Henwen.new(:used => false)
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object.save

      assert object.persisted?
    end
  end

  def test_update
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object = Henwen.new(:used => false)
      object.save

      stub_response(:put, fake_response(200, "OK", "instance_used_model")) do
        object.update(:used => true)

        assert object.used
      end
    end
  end

  def test_find
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      ref = Henwen.create(:used => false).ref

      stub_response(:get, fake_response(200, "OK", "instance_model")) do
        object = Henwen.find(ref)

        assert_equal ref, object.ref
        assert object.persisted?
      end
    end
  end

  def test_destroy
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object = Henwen.create(:used => false)

      stub_response(:delete, fake_response(204, "No Content", nil)) do
        object.destroy

        assert !object.ref
        assert object.destroyed?
      end
    end
  end
end
