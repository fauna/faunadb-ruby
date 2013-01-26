require File.expand_path('../test_helper', __FILE__)

class EventTest < MiniTest::Unit::TestCase
  def setup
      Fauna::Class.create("henwen")
      @timeline_ref = Fauna::TimelineSettings.create("comments")["resource"]["ref"]
      @event_ref = Fauna::Instance.create("henwen")["resource"]["ref"]
      @resource_ref = Fauna::User.create(:name => "Taran", :email => "taran#{SecureRandom.hex}@example.com")["resource"]["ref"]
  end

  def test_event_create
      response = Fauna::Event.create("#{@resource_ref}/#{@timeline_ref}", @event_ref)
      assert_match %r{users/\d+/timelines/comments}, response["resource"]["ref"]
      assert_equal "henwen", response["references"][@event_ref]["class"]
  end

  def test_event_find
      Fauna::Event.create("#{@resource_ref}/#{@timeline_ref}", @event_ref)
      response = Fauna::Event.find("#{@resource_ref}/#{@timeline_ref}")
      assert_match %r{users/\d+/timelines/comments}, response["resource"]["ref"]
      assert_equal "henwen", response["references"][@event_ref]["class"]
  end

  def test_event_delete
      Fauna::Event.create("#{@resource_ref}/#{@timeline_ref}", @event_ref)
      response = Fauna::Event.delete("#{@resource_ref}/#{@timeline_ref}", @event_ref)
      assert_match %r{users/\d+/timelines/comments}, response["resource"]["ref"]
      assert_equal "henwen", response["references"][@event_ref]["class"]
  end
end
