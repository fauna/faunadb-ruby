require File.expand_path('../../test_helper', __FILE__)

class ClassTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class Pigkeeper < Fauna::Class
    field :visited
  end

  def setup
    super
    Pigkeeper.save!
    @model = Pigkeeper.new
  end

  def test_class_name
    assert_equal 'classes/pigkeeper', Pigkeeper.ref
  end

  def test_class_save
    Pigkeeper.data["class_visited"] = true
    Pigkeeper.save!
    Pigkeeper.reload!
    assert Pigkeeper.data["class_visited"]
  end

  def test_create
    object = Pigkeeper.create(:visited => false)
    assert_equal false, object.visited
    assert object.persisted?
    assert object.ref
  end

  def test_save
    object = Pigkeeper.new(:visited => false)
    object.save
    assert object.persisted?
  end

  def test_update
    object = Pigkeeper.new(:visited => false)
    object.save
    object.update(:visited => true)
    assert object.visited
  end

  def test_find
    object = Pigkeeper.create(:visited => false)
    object1 = Pigkeeper.find(object.ref)
    assert_equal object.ref, object1.ref
    assert object1.persisted?
  end

  def test_destroy
    object = Pigkeeper.create(:visited => false)
    object.destroy
    assert object.destroyed?
  end
end
