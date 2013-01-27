require File.expand_path('../../test_helper', __FILE__)

class UserTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class User < Fauna::User
    field :pockets
  end

  def setup
    super
    @model = User.new
    @attributes = {:name => 'Taran', :email => email, :password => password, :pockets => "Piggy treats."}
  end

  # def test_class_name
  #   assert_equal 'users', User.ref
  # end

  def test_create
    Fauna::Client.context(@publisher_connection) do
      user = User.create(@attributes)
      assert_equal 'Taran', user.name
      assert user.persisted?
      assert user.ref
    end
  end

  def test_save
    Fauna::Client.context(@publisher_connection) do
      user = User.new(@attributes)
      user.save
      assert user.persisted?
    end
  end

  def test_update
    Fauna::Client.context(@publisher_connection) do
      user = User.new(@attributes)
      user.save
      user.update(:name => "Henwen")
      assert_equal 'Henwen', user.name
    end
  end

  def test_find
    Fauna::Client.context(@publisher_connection) do
      user = User.create(@attributes)
      user1 = User.find(user.ref)
      assert_equal user.ref, user1.ref
      assert user1.persisted?
    end
  end

  def test_destroy
    Fauna::Client.context(@publisher_connection) do
      user = User.create(@attributes)
      user.destroy
      assert user.destroyed?
    end
  end

  def test_find_by_email
    Fauna::Client.context(@publisher_connection) do
      user = User.create(@attributes)
      assert_equal [user], User.find_by_email(email)
    end
  end

  def test_authenticate
    Fauna::Client.context(@publisher_connection) do
      User.create(@attributes)
      user = User.find_by_email(@attributes['email'])
      assert_equal true, user.authenticate('tnT8m&vwm')
      assert_equal false, user.authenticate('badpassw')
    end
  end
end
