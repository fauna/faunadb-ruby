require File.expand_path('../test_helper', __FILE__)

class UserTest < MiniTest::Unit::TestCase
  def test_user_create
    stub_response(:post, fake_response(201, "Created", "user")) do
      response = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")

      assert_equal "Taran", response["resource"]["name"]
      assert_match %r{users/\d+}, response["resource"]["ref"]

      stub_response(:delete, fake_response(204, "No Content", nil)) do
        Fauna::User.delete(response["resource"]["ref"])
      end
    end
  end

  def test_user_find_single
    stub_response(:post, fake_response(201, "Created", "user")) do
      user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
      ref = user["resource"]["ref"]

      stub_response(:get, fake_response(200, "OK", "user")) do
        response = Fauna::User.find(ref)

        assert_equal "Taran", response["resource"]["name"]
        assert_match %r{users/\d+}, response["resource"]["ref"]

        stub_response(:delete, fake_response(204, "No Content", nil)) do
          Fauna::User.delete(ref)
        end
      end
    end
  end

  def test_user_find_multiple
    stub_response(:post, fake_response(201, "Created", "users")) do
      Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")

      stub_response(:get, fake_response(200, "OK", "users")) do
        response = Fauna::User.find("users")
        user = response["resources"][0]

        assert_equal "Taran", user["name"]
        assert_match %r{users/\d+}, user["ref"]

        stub_response(:delete, fake_response(204, "No Content", nil)) do
          Fauna::User.delete(user["ref"])
        end
      end
    end
  end

  def test_user_update
    stub_response(:post, fake_response(201, "Created", "user")) do
      user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
      ref = user["resource"]["ref"]

      stub_response(:put, fake_response(200, "OK", "user_with_pockets")) do
        response = Fauna::User.update(ref, { "data" => { "pockets" => 2 } })

        assert_equal "Taran", response["resource"]["name"]
        assert_match %r{users/\d+}, response["resource"]["ref"]
        assert_equal 2, response["resource"]["data"]["pockets"]

        stub_response(:delete, fake_response(204, "No Content", nil)) do
          Fauna::User.delete(ref)
        end
      end
    end
  end

  def test_user_delete
    stub_response(:post, fake_response(201, "Created", "user")) do
      user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
      ref = user["resource"]["ref"]

      stub_response(:delete, fake_response(204, "No Content", nil)) do
        Fauna::User.delete(ref)

        stub_response(:get, fake_response(404, "Not Found", "user_deleted")) do
          begin
            Fauna::User.find(ref)
          rescue Exception => e
            assert_equal RestClient::ResourceNotFound, e.class
          end
        end
      end
    end
  end

  def test_user_stats
    stub_response(:post, fake_response(201, "Created", "user")) do
      user = Fauna::User.create(:email => "taran#{SecureRandom.hex}@example.com", :password => "tnT8m&vwm", :name => "Taran")
      ref = user["resource"]["ref"]

      stub_response(:get, fake_response(200, "OK", "user_stats")) do
        response = Fauna::User.get_stats(ref)

        assert_equal "#{ref}/stats", response["resource"]["ref"]
        assert_equal 0, response["resource"]["instances"]
        assert_equal 0, response["resource"]["tokens"]

        stub_response(:delete, fake_response(204, "No Content", nil)) do
          Fauna::User.delete(ref)
        end
      end
    end
  end
end
