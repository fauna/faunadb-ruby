require File.expand_path('../test_helper', __FILE__)

class DatabaseTest < MiniTest::Unit::TestCase

  def setup
    super
    @model = Fauna::Database.new("ref" => "databases/fauna-ruby-test2")
    Fauna::Client.context(@root_connection) do
      @model.save
    end
  end

  def test_create
    assert_raises(Fauna::Connection::Unauthorized) do
      @model.save
    end
  end

  def test_find
    assert_raises(Fauna::Connection::Unauthorized) do
      Fauna::Database.find(@model.ref)
    end
    Fauna::Client.context(@root_connection) do
      assert_equal @model, Fauna::Database.find(@model.ref)
    end
  end

  def test_self
    database = Fauna::Resource.find('databases/self')
    assert_equal "databases/fauna-ruby-test", database.ref

    assert_raises(Fauna::Connection::BadRequest) do
      Fauna::Client.context(@root_connection) do
        Fauna::Resource.find('databases/self')
      end
    end
  end

  def test_destroy
    assert_raises(Fauna::Connection::Unauthorized) do
      Fauna::Resource.find('databases/self').delete
    end
    Fauna::Client.context(@root_connection) do
      @model.delete
    end
  end
end
