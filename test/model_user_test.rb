require File.expand_path('../test_helper', __FILE__)

require "fauna/model/user"

class ModelTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class User < Fauna::Model::User
    data_attr :pockets
  end

  def setup
    @model = User.new
  end

  def test_class_name
    assert_equal 'ModelTest::User', User.class_name
  end

  def test_class_setup
    assert_equal 'users', User.ref
  end

  def test_initialize
    object = User.new

    assert !object.ref
    assert object.new_record?
  end

  def test_create
    stub_response(:post, fake_response(201, "Created", "user")) do
      object = User.create(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')

      assert object.persisted?
      assert object.ref
    end
  end

  def test_save
    object = User.new(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')
    stub_response(:post, fake_response(201, "Created", "user")) do
      object.save

      assert object.persisted?
    end
  end

  def test_update
    stub_response(:post, fake_response(201, "Created", "user")) do
      object = User.new(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')
      object.save

      stub_response(:put, fake_response(200, "OK", "user_with_pockets")) do
        object.update(:pockets => 2)

        assert_equal 2, object.pockets
      end
    end
  end

  def test_find
    stub_response(:post, fake_response(201, "Created", "user")) do
      object = User.create(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')
      ref = object.ref
      id = object.id

      stub_response(:get, fake_response(200, "OK", "user")) do
        object1 = User.find(ref)
        object2 = User.find(id)

        assert_equal object1.ref, object2.ref
        assert_equal ref, object1.ref
        assert object1.persisted?
      end
    end
  end

  def test_find_by_email
    stub_response(:post, fake_response(201, "Created", "user")) do
      email = "taran#{SecureRandom.hex}@example.com"
      object = User.create(:name => 'Taran', :email => email, :password => 'tnT8m&vwm')

      stub_response(:get, fake_response(200, "OK", "users")) do
        assert_equal object, User.find_by_email(email)
      end
    end
  end

  def test_authenticate
    stub_response(:post, fake_response(201, "Created", "user")) do
      email = "taran#{SecureRandom.hex}@example.com"
      User.create(:name => 'Taran', :email => email, :password => 'tnT8m&vwm')

      stub_response(:get, fake_response(200, "OK", "users")) do
        user = User.find_by_email(email)

        assert_equal true, user.authenticate('tnT8m&vwm')
        assert_equal false, user.authenticate('badpassw')
      end
    end
  end

  def test_destroy
    stub_response(:post, fake_response(201, "Created", "user")) do
      object = User.create(:name => 'Taran', :email => 'taran#{SecureRandom.hex}@example.com', :password => 'tnT8m&vwm')

      stub_response(:delete, fake_response(204, "No Content", nil)) do
        object.destroy

        assert !object.ref
        assert object.destroyed?
        assert object.id
      end
    end
  end
end
