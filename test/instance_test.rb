require File.expand_path('../test_helper', __FILE__)

class InstanceTest < MiniTest::Unit::TestCase
  def setup
      Fauna::Class.create("henwen")
  end

  def test_instance_create
      response = Fauna::Instance.create("henwen")
      assert_equal "henwen", response["resource"]["class"]
      assert_match %r{instances/\d+}, response["resource"]["ref"]
  end

  def test_instance_find_single
      instance = Fauna::Instance.create("henwen")
      ref = instance["resource"]["ref"]
        response = Fauna::Instance.find(ref)
        assert_equal "henwen", response["resource"]["class"]
        assert_match ref, response["resource"]["ref"]
  end

  def test_instance_find_multiple
      Fauna::Instance.create("henwen")
        response = Fauna::Instance.find("instances")
        ref = response["references"].select{ |k, v| k =~ /instances/}.to_a[0][0]
        assert_match %r{instances/\d+}, response["references"][ref]["ref"]
  end

  def test_instance_update
      instance = Fauna::Instance.create("henwen")
      ref = instance["resource"]["ref"]
        response = Fauna::Instance.update(ref, { "data" => { "used" => true } })
        assert_equal "henwen", response["resource"]["class"]
        assert_match %r{instances/\d+}, response["resource"]["ref"]
        assert_equal true, response["resource"]["data"]["used"]
  end

  def test_instance_delete
      instance = Fauna::Instance.create("henwen")
      ref = instance["resource"]["ref"]
        Fauna::Instance.delete(ref)
          begin
            Fauna::Instance.find(ref)
          rescue Exception => e
            assert_equal RestClient::ResourceNotFound, e.class
          end
  end
end
