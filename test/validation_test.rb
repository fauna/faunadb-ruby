require File.expand_path('../test_helper', __FILE__)

class ClassValidationTest < MiniTest::Unit::TestCase
  def test_validates_presence_of_field
    h = Pigkeeper.new(:visited => nil)
    refute h.valid?
    refute h.save
    assert_equal ["can't be blank"], h.errors[:visited],

    h.visited = true
    assert h.save
  end

  def test_fails_save!
    h = Pigkeeper.new(:visited => nil)
    assert_raises(Fauna::Invalid) { h.save! }
  end

  def test_validate_callback
    h = Pigkeeper.new(:visited => true, :pockets => 0)
    refute h.valid?
    refute h.save
    assert_equal ["must be full of piggy treats"], h.errors[:pockets]

    h.pockets = 1
    assert h.save
  end
end
