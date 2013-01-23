require File.expand_path('../test_helper', __FILE__)

require "fauna/model"

class ModelValidationTest < ActiveModel::TestCase

  stub_response(:put, fake_response(200, "OK", "class_model")) do
    class Henwen < Fauna::Model
      data_attr :used, :price
      validates :used, :presence => true

      validate :price_is_greater_than_zero

      def price_is_greater_than_zero
        errors.add :price, 'must be greater than 0' if price <= 0 unless price.blank?
      end
    end
  end

  def test_validates_presence_of
    h = Henwen.new(:used => nil)
    assert !h.valid?, "should not be a valid resource without used"
    assert !h.save, "should not have saved an invalid resource"
    assert_equal ["can't be blank"], h.errors[:used], "should have an error on used"

    h.used = true
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      assert h.save, "should have saved after fixing the validation, but had: #{h.errors.inspect}"
    end
  end

  def test_fails_save!
    h = Henwen.new(:used => nil)
    assert_raise(Fauna::ResourceInvalid) { h.save! }
  end

  def test_validate_callback
    h = Henwen.new(:used => true, :price => 0)
    assert !h.valid?, "should not be a valid resource when it fails a validation callback"
    assert !h.save, "should not have saved an invalid resource"
    assert_equal ["must be greater than 0"], h.errors[:price], "should be an error on price"

    h.price = 1
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      assert h.save, "should have saved after fixing the validation, but had: #{h.errors.inspect}"
    end
  end
end
