require File.expand_path('../../test_helper', __FILE__)

class UserTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class Fauna::User
    field :pockets
  end

  def setup
    super
    @model = Fauna::User.new
    @attributes = {:name => 'Taran', :email => email, :password => password, :pockets => "Piggy treats."}
  end

  def test_create
    user = Fauna::User.create(@attributes)
    assert_equal 'Taran', user.name
    assert user.persisted?
    assert user.ref
  end

  def test_save
    user = Fauna::User.new(@attributes)
    user.save
    assert user.persisted?
  end

  def test_update
    user = Fauna::User.new(@attributes)
    user.save
    user.update(:pockets => "Nothing")
    assert_equal 'Nothing', user.pockets
  end

  def test_changes
    user = Fauna::User.new(@attributes)
    user.save
    user.update(:pockets => "Nothing")
    assert_equal user.changes.page.events.length, 2
  end

  def test_find
    user = Fauna::User.create(@attributes)
    user1 = Fauna::User.find(user.ref)
    assert_equal user.ref, user1.ref
    assert user1.persisted?
    assert_equal user1.pockets, user.pockets
  end

  def test_destroy
    user = Fauna::User.create(@attributes)
    user.destroy
    assert user.destroyed?
  end

  def test_find_by_email
    user = Fauna::User.create(@attributes.merge(:email => 'test@example.com'))
    assert_equal [user], Fauna::User.find_by_email('test@example.com')
  end

  def test_find_by_name
    user = Fauna::User.create(@attributes.merge(:name => 'Henwen'))
    assert_equal [user], Fauna::User.find_by_name('Henwen')
  end
end
