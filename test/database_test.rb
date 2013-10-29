require File.expand_path('../test_helper', __FILE__)

class DatabaseTest < MiniTest::Unit::TestCase

  def setup
    super
    @model = Fauna::Resource.new 'databases', :name => 'fauna-ruby-test2'
    Fauna::Client.context(@root_connection) do
      @model.save
    end
  end

  def test_get
    assert_raises(Fauna::Connection::NotFound) do
      Fauna::Resource.find("databases/fauna-ruby-test")
    end
    Fauna::Client.context(@root_connection) do
      Fauna::Resource.find("databases/fauna-ruby-test")
      Fauna::Resource.find("databases/fauna-ruby-test2")
    end
  end

  def test_create
    assert_raises(Fauna::Connection::NotFound) do
      @model.save
    end
    Fauna::Client.context(@root_connection) do
      @model.save
    end
  end

  def test_destroy
    assert_raises(Fauna::Connection::NotFound) do
      @model.delete
    end
    Fauna::Client.context(@root_connection) do
      @model.delete
    end
  end
end
