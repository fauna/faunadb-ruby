require File.expand_path('../test_helper', __FILE__)

class WorldTest < ActiveModel::TestCase
  # include ActiveModel::Lint::Tests

  class Fauna::World
    field :visited
  end

  def setup
    super
    @model = Fauna::World.new("ref" => "worlds/fauna-ruby-test2")
    Fauna::Client.context(@root_connection) do
      @model.save!
    end
  end

  def test_create
    assert_raises(Fauna::Connection::Unauthorized) do
      @model.save!
    end
  end

  def test_find
    assert_raises(Fauna::Connection::Unauthorized) do
      Fauna::World.find_by_ref(@model.ref)
    end
    Fauna::Client.context(@root_connection) do
      assert_equal @model, Fauna::World.find_by_ref(@model.ref)
    end
  end

  def test_self
    world = Fauna::World.self
    assert_equal "worlds/fauna-ruby-test", world.ref

    assert_raises(Fauna::Connection::BadRequest) do
      Fauna::Client.context(@root_connection) do
        Fauna::World.self
      end
    end
  end

  def test_destroy
    assert_raises(Fauna::Connection::Unauthorized) do
      Fauna::World.self.destroy
    end
    Fauna::Client.context(@root_connection) do
      @model.destroy
    end
  end
end
