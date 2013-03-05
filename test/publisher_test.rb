require File.expand_path('../test_helper', __FILE__)

class PublisherTest < ActiveModel::TestCase
  # include ActiveModel::Lint::Tests

  class Fauna::Publisher
    field :visited
  end

  def setup
    super
    @model = Fauna::Publisher.find
    @attributes = {:visited => true}
  end

  def test_create
    assert_raises(Fauna::Invalid) do
      Fauna::Publisher.create
    end
  end

  def test_save
    publisher = Fauna::Publisher.new
    assert !publisher.persisted?
    assert_raises(Fauna::Invalid) do
      publisher.save
    end

    publisher = Fauna::Publisher.find
    publisher.save
  end

  def test_update
    Fauna::Publisher.find.update(@attributes)
    assert_equal true, Fauna::Publisher.find.visited
  end

  def test_find
    publisher = Fauna::Publisher.find
    assert_equal "publisher", publisher.ref
  end

  def test_destroy
    assert_raises(Fauna::Invalid) do
      Fauna::Publisher.find.destroy
    end
  end
end
