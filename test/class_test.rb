require File.expand_path('../test_helper', __FILE__)

class ClassTest < MiniTest::Unit::TestCase
  def test_class_create
      response = Fauna::Class.create("henwen")
      assert_equal "henwen", response["resource"]["name"]
      assert_equal "classes/henwen", response["resource"]["ref"]
  end

  def test_class_find_single
      Fauna::Class.create("henwen")
        response = Fauna::Class.find("classes/henwen")
        assert_equal "henwen", response["resource"]["name"]
        assert_equal "classes/henwen", response["resource"]["ref"]
  end

  def test_class_find_multiple
      Fauna::Class.create("henwen")
        resources = Fauna::Class.find("classes")["resources"]
        resources = resources.select{ |res| res["name"] == "henwen" }
        assert_equal "classes/henwen", resources[0]["ref"]
  end

  def test_class_delete
      Fauna::Class.create("henwen")
        Fauna::Class.delete("classes/henwen")
          begin
            Fauna::Class.find("classes/henwen")
          rescue Exception => e
            assert_equal RestClient::ResourceNotFound, e.class
          end
  end

  def test_class_stats
      Fauna::Class.create("henwen")
        response = Fauna::Class.get_stats("classes/henwen")
        assert_equal "classes/henwen/stats", response["resource"]["ref"]
        assert_equal 0, response["resource"]["instances"]
      end
end
