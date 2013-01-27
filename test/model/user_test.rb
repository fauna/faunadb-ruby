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
    user = User.create(@attributes)
    assert_equal 'Taran', user.name
    assert user.persisted?
    assert user.ref
  end

  def test_save
    user = User.new(@attributes)
    user.save
    assert user.persisted?
  end

  def test_update
    user = User.new(@attributes)
    user.save
    user.update(:pockets => "Nothing")
    assert_equal 'Nothing', user.pockets
  end

  def test_find
    user = User.create(@attributes)
    user1 = User.find(user.ref)
    assert_equal user.ref, user1.ref
    assert user1.persisted?
  end

  def test_destroy
    user = User.create(@attributes)
    user.destroy
    assert user.destroyed?
  end

  def test_find_by_email
    user = User.create(@attributes.merge(:email => 'test@example.com'))
    assert_equal [user], User.find_by_email('test@example.com')
  end

  def test_find_by_name
    user = User.create(@attributes.merge(:name => 'Henwen'))
    assert_equal [user], User.find_by_name('Henwen')
  end
end
