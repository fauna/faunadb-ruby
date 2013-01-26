require File.expand_path('../test_helper', __FILE__)

class UserTest < MiniTest::Unit::TestCase
  def test_user_create
    response = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
    assert_equal "Taran", response["resource"]["name"]
    assert_match %r{users/\d+}, response["resource"]["ref"]
    Fauna::User.delete(response["resource"]["ref"])
  end

  def test_user_find_single
    user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
    ref = user["resource"]["ref"]
    response = Fauna::User.find(ref)
    assert_equal "Taran", response["resource"]["name"]
    assert_match %r{users/\d+}, response["resource"]["ref"]
    Fauna::User.delete(ref)
  end

  def test_user_find_multiple
    Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
    response = Fauna::User.find("users")
    user = response["resources"][0]
    assert_equal "Taran", user["name"]
    assert_match %r{users/\d+}, user["ref"]
    Fauna::User.delete(user["ref"])
  end

  def test_user_update
    user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
    ref = user["resource"]["ref"]
    response = Fauna::User.update(ref, { "data" => { "pockets" => 2 } })
    assert_equal "Taran", response["resource"]["name"]
    assert_match %r{users/\d+}, response["resource"]["ref"]
    assert_equal 2, response["resource"]["data"]["pockets"]
    Fauna::User.delete(ref)
  end

  def test_user_delete
    user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
    ref = user["resource"]["ref"]
    Fauna::User.delete(ref)
    begin
      Fauna::User.find(ref)
    rescue Exception => e
      assert_equal RestClient::ResourceNotFound, e.class
    end
  end

  def test_user_stats
    user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
    ref = user["resource"]["ref"]
    response = Fauna::User.get_stats(ref)
    assert_equal "#{ref}/stats", response["resource"]["ref"]
    assert_equal 0, response["resource"]["instances"]
    assert_equal 0, response["resource"]["tokens"]
    Fauna::User.delete(ref)
  end
end
