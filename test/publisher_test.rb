require File.expand_path('../test_helper', __FILE__)

class WorldTest < ActiveModel::TestCase
  # include ActiveModel::Lint::Tests

  class Fauna::World
    field :visited
  end

  def setup
    super
    @model = Fauna::World.find
    @attributes = {:visited => true}
  end

  def test_create
    assert_raises(Fauna::Invalid) do
      Fauna::World.create
    end
  end

  def test_save
    world = Fauna::World.new
    assert !world.persisted?
    assert_raises(Fauna::Invalid) do
      world.save
    end

    world = Fauna::World.find
    world.save
  end

  def test_update
    Fauna::World.find.update(@attributes)
    assert_equal true, Fauna::World.find.visited
  end

  def test_find
    world = Fauna::World.find
    assert_equal "world", world.ref
  end

  def test_destroy
    assert_raises(Fauna::Invalid) do
      Fauna::World.find.destroy
    end
  end
end
