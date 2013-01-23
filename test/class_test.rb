require File.expand_path('../test_helper', __FILE__)

class ClassTest < MiniTest::Unit::TestCase
  def test_class_create
    stub_response(:put, fake_response(201, "Created", "class")) do
      response = Fauna::Class.create("henwen")

      assert_equal "henwen", response["resource"]["name"]
      assert_equal "classes/henwen", response["resource"]["ref"]
    end
  end

  def test_class_find_single
    stub_response(:put, fake_response(201, "Created", "class")) do
      Fauna::Class.create("henwen")

      stub_response(:get, fake_response(200, "OK", "class")) do
        response = Fauna::Class.find("classes/henwen")

        assert_equal "henwen", response["resource"]["name"]
        assert_equal "classes/henwen", response["resource"]["ref"]
      end
    end
  end

  def test_class_find_multiple
    stub_response(:put, fake_response(201, "Created", "class")) do
      Fauna::Class.create("henwen")

      stub_response(:get, fake_response(200, "OK", "classes")) do
        resources = Fauna::Class.find("classes")["resources"]

        resources = resources.select{ |res| res["name"] == "henwen" }

        assert_equal "classes/henwen", resources[0]["ref"]
      end
    end
  end

  def test_class_delete
    stub_response(:put, fake_response(201, "Created", "class")) do
      Fauna::Class.create("henwen")

      stub_response(:delete, fake_response(200, "OK", nil)) do
        Fauna::Class.delete("classes/henwen")

        stub_response(:get, fake_response(404, "Not Found", "class_deleted")) do
          begin
            Fauna::Class.find("classes/henwen")
          rescue Exception => e
            assert_equal RestClient::ResourceNotFound, e.class
          end
        end
      end
    end
  end

  def test_class_stats
    stub_response(:put, fake_response(201, "Created", "class")) do
      Fauna::Class.create("henwen")

      stub_response(:get, fake_response(200, "OK", "class_stats")) do
        response = Fauna::Class.get_stats("classes/henwen")

        assert_equal "classes/henwen/stats", response["resource"]["ref"]
        assert_equal 0, response["resource"]["instances"]
      end
    end
  end
end
