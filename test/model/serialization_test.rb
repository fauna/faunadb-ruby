require File.expand_path('../../test_helper', __FILE__)

require "fauna/model"

class ModelSerializationTest < MiniTest::Unit::TestCase
  class Henwen < Fauna::Model
    data_attr :used
  end

  def test_serializable_hash
    object = Henwen.create(:used => false)
    hash = object.serializable_hash
    assert_equal false, hash["data"]["used"]
    assert_match %r{instances/\d+}, hash["ref"]
  end
end
