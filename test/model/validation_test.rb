require File.expand_path('../../test_helper', __FILE__)

class ClassValidationTest < MiniTest::Unit::TestCase
  def setup
    super
    Pigkeeper.save!
  end

  def test_validates_presence_of
    h = Pigkeeper.new(:visited => nil)
    assert !h.valid?, "should not be a valid resource without visited"
    assert !h.save, "should not have saved an invalid resource"
    assert_equal ["can't be blank"], h.errors[:visited], "should have an error on visited"

    h.visited = true
    assert h.save, "should have saved after fixing the validation, but had: #{h.errors.inspect}"
  end

  def test_fails_save!
    h = Pigkeeper.new(:visited => nil)
    assert_raises(Fauna::Invalid) { h.save! }
  end

  def test_validate_callback
    h = Pigkeeper.new(:visited => true, :pockets => 0)
    assert !h.valid?, "should not be a valid resource when it fails a validation callback"
    assert !h.save, "should not have saved an invalid resource"
    assert_equal ["must be full of piggy treats"], h.errors[:pockets], "should be an error on pockets"

    h.pockets = 1
    assert h.save, "should have saved after fixing the validation, but had: #{h.errors.inspect}"
  end
end
