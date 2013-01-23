require File.expand_path('../test_helper', __FILE__)

class InstanceTest < MiniTest::Unit::TestCase
  def setup
    stub_response(:put, fake_response(201, "Created", "class")) do
      Fauna::Class.create("henwen")
    end
  end

  def test_instance_create
    stub_response(:post, fake_response(201, "Created", "instance")) do
      response = Fauna::Instance.create("henwen")

      assert_equal "henwen", response["resource"]["class"]
      assert_match %r{instances/\d+}, response["resource"]["ref"]
    end
  end

  def test_instance_find_single
    stub_response(:post, fake_response(201, "Created", "instance")) do
      instance = Fauna::Instance.create("henwen")
      ref = instance["resource"]["ref"]

      stub_response(:get, fake_response(200, "OK", "instance")) do
        response = Fauna::Instance.find(ref)

        assert_equal "henwen", response["resource"]["class"]
        assert_match ref, response["resource"]["ref"]
      end
    end
  end

  def test_instance_find_multiple
    stub_response(:post, fake_response(201, "Created", "instance")) do
      Fauna::Instance.create("henwen")

      stub_response(:get, fake_response(200, "OK", "instances")) do
        response = Fauna::Instance.find("instances")
        ref = response["references"].select{ |k, v| k =~ /instances/}.to_a[0][0]

        assert_match %r{instances/\d+}, response["references"][ref]["ref"]
      end
    end
  end

  def test_instance_update
    stub_response(:post, fake_response(201, "Created", "instance")) do
      instance = Fauna::Instance.create("henwen")
      ref = instance["resource"]["ref"]

      stub_response(:put, fake_response(200, "OK", "instance_used")) do
        response = Fauna::Instance.update(ref, { "data" => { "used" => true } })

        assert_equal "henwen", response["resource"]["class"]
        assert_match %r{instances/\d+}, response["resource"]["ref"]
        assert_equal true, response["resource"]["data"]["used"]
      end
    end
  end

  def test_instance_delete
    stub_response(:post, fake_response(201, "Created", "user")) do
      instance = Fauna::Instance.create("henwen")
      ref = instance["resource"]["ref"]

      stub_response(:delete, fake_response(204, "No Content", nil)) do
        Fauna::Instance.delete(ref)

        stub_response(:get, fake_response(404, "Not Found", "instance_deleted")) do
          begin
            Fauna::Instance.find(ref)
          rescue Exception => e
            assert_equal RestClient::ResourceNotFound, e.class
          end
        end
      end
    end
  end
end
