require File.expand_path('../test_helper', __FILE__)

require "fauna/model"

class ModelSerializationTest < MiniTest::Unit::TestCase
  stub_response(:put, fake_response(200, "OK", "class_model")) do
    class Henwen < Fauna::Model
      data_attr :used
    end
  end

  def test_serializable_hash
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object = Henwen.create(:used => false)
      hash = object.serializable_hash

      assert_equal false, hash["data"]["used"]
      assert_match %r{instances/\d+}, hash["ref"]
    end
  end
end
