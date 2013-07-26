require File.expand_path('../test_helper', __FILE__)

class DatabaseTest < ActiveModel::TestCase
  # include ActiveModel::Lint::Tests

  class Fauna::Database
    field :visited
  end

  def setup
    super
    @model = Fauna::Database.new("ref" => "databases/fauna-ruby-test2")
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
      Fauna::Database.find_by_ref(@model.ref)
    end
    Fauna::Client.context(@root_connection) do
      assert_equal @model, Fauna::Database.find_by_ref(@model.ref)
    end
  end

  def test_self
    database = Fauna::Database.self
    assert_equal "databases/fauna-ruby-test", database.ref

    assert_raises(Fauna::Connection::BadRequest) do
      Fauna::Client.context(@root_connection) do
        Fauna::Database.self
      end
    end
  end

  def test_destroy
    assert_raises(Fauna::Connection::Unauthorized) do
      Fauna::Database.self.destroy
    end
    Fauna::Client.context(@root_connection) do
      @model.destroy
    end
  end
end
