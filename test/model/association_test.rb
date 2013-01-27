require File.expand_path('../../test_helper', __FILE__)

class AssociationTest < MiniTest::Unit::TestCase
  class ::Pig < Fauna::Class
    field :name
    timeline :visions
  end

  class ::Vision < Fauna::Class
    field :text
    reference :pig
  end

  def setup
    super
    # Fauna::Timeline.create("comments")
  end

  def test_timeline
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_reference
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end
end
