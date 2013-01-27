require File.expand_path('../../test_helper', __FILE__)

require "fauna/class"

class ClassValidationTest < MiniTest::Unit::TestCase

  class TestClass < Fauna::Class
    field :used, :price
    validates :used, :presence => true

    validate :price_is_greater_than_zero

    def price_is_greater_than_zero
      errors.add :price, 'must be greater than 0' if price <= 0 unless price.blank?
    end
  end

  def test_validates_presence_of
    h = TestClass.new(:used => nil)
    assert !h.valid?, "should not be a valid resource without used"
    assert !h.save, "should not have saved an invalid resource"
    assert_equal ["can't be blank"], h.errors[:used], "should have an error on used"

    h.used = true
    assert h.save, "should have saved after fixing the validation, but had: #{h.errors.inspect}"
  end

  def test_fails_save!
    h = TestClass.new(:used => nil)
    assert_raises(Fauna::ResourceInvalid) { h.save! }
  end

  def test_validate_callback
    h = TestClass.new(:used => true, :price => 0)
    assert !h.valid?, "should not be a valid resource when it fails a validation callback"
    assert !h.save, "should not have saved an invalid resource"
    assert_equal ["must be greater than 0"], h.errors[:price], "should be an error on price"

    h.price = 1
    assert h.save, "should have saved after fixing the validation, but had: #{h.errors.inspect}"
  end
end
