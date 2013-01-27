require File.expand_path('../../test_helper', __FILE__)

require "fauna/class"

class ClassSerializationTest < MiniTest::Unit::TestCase
  class TestClass < Fauna::Class
    field :used
  end

  def test_serializable_hash
    object = TestClass.create(:used => false)
    hash = object.serializable_hash
    assert_equal false, hash["data"]["used"]
    assert_match %r{instances/\d+}, hash["ref"]
  end
end
