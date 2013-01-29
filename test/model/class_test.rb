require File.expand_path('../../test_helper', __FILE__)

class ClassTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  def setup
    super
    @model = Pig.new
  end

  def test_class_name
    assert_equal 'classes/pig', Pig.ref
  end

  def test_class_save
    Pig.update_data! do |data|
      data["class_visited"] = true
    end
    assert Pig.data["class_visited"]
  end

  def test_create
    pig = Pig.create(:visited => false)
    assert_equal false, pig.visited
    assert pig.persisted?
    assert pig.ref
  end

  def test_save
    pig = Pig.new(:visited => false)
    pig.save
    assert pig.persisted?
  end

  def test_update
    pig = Pig.new(:visited => false)
    pig.save
    pig.update(:visited => true)
    assert pig.visited
  end

  def test_changes
    pig = Pig.new(:visited => true)
    pig.save
    pig.update(:visited => false)
    assert_equal pig.changes.page.events.length, 2
  end

  def test_find
    pig = Pig.create(:visited => false)
    pig1 = Pig.find(pig.ref)
    assert_equal pig.ref, pig1.ref
    assert pig1.persisted?
  end

  def test_destroy
    pig = Pig.create(:visited => false)
    pig.destroy
    assert pig.destroyed?
  end
end
