require File.expand_path('../../test_helper', __FILE__)

require "fauna/model/user"

class ModelUserTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class User < Fauna::Model::User
    data_attr :pockets
  end

  def setup
    @model = User.new
  end

  def test_class_name
    assert_equal 'ModelUserTest::User', User.class_name
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
    object = User.create(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')
    assert object.persisted?
    assert object.ref
  end

  def test_save
    object = User.new(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')
    object.save
    assert object.persisted?
  end

  def test_update
    object = User.new(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')
    object.save
    object.update(:pockets => 2)
    assert_equal 2, object.pockets
  end

  def test_find
    object = User.create(:name => 'Taran', :email => "taran#{SecureRandom.hex}@example.com", :password => 'tnT8m&vwm')
    ref = object.ref
    id = object.id
    object1 = User.find(ref)
    object2 = User.find(id)
    assert_equal object1.ref, object2.ref
    assert_equal ref, object1.ref
    assert object1.persisted?
  end

  def test_find_by_email
    email = "taran#{SecureRandom.hex}@example.com"
    object = User.create(:name => 'Taran', :email => email, :password => 'tnT8m&vwm')
    assert_equal object, User.find_by_email(email)
  end

  def test_authenticate
    user = nil
    email = "taran#{SecureRandom.hex}@example.com"
    User.create(:name => 'Taran', :email => email, :password => 'tnT8m&vwm')
    user = User.find_by_email(email)
    assert_equal true, user.authenticate('tnT8m&vwm')
    assert_equal false, user.authenticate('badpassw')
  end

  def test_destroy
    object = User.create(:name => 'Taran', :email => 'taran#{SecureRandom.hex}@example.com', :password => 'tnT8m&vwm')
    object.destroy
    assert !object.ref
    assert object.destroyed?
    assert object.id
  end
end
