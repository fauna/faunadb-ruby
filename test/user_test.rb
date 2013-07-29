require File.expand_path("../test_helper", __FILE__)

class UserTest < MiniTest::Unit::TestCase

  def setup
    super
    @model = Fauna::User.new
    @attributes = { :data => { :name => "Gurgi", :pockets => "Piggy treats." }, :email => email, :password => password }
  end

  def test_create
    user = Fauna::User.create(@attributes)
    assert_equal "Gurgi", user.data['name']
    assert user.persisted?
    assert user.ref
  end

  def test_all
    user = Fauna::User.create(@attributes)
    assert Fauna::User.all.page.include?(user.ref)
  end

  def test_find_by_email
    user = Fauna::User.create(@attributes.merge(:email => "test@example.com"))
    assert_equal user, Fauna::User.find_by_email("test@example.com")
  end

  def test_find_by_constraint
    user = Fauna::User.create(@attributes.merge(:constraints => { :name => 'henwen' }))
    assert_equal user, Fauna::User.find_by_constraint('name', 'henwen')
  end
end
