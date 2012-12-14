require File.expand_path('../test_helper', __FILE__)

class ResourceTest < MiniTest::Unit::TestCase
  def test_resource_cannot_be_instantiated
    assert !Fauna::Resource.respond_to?(:new)
  end
end
