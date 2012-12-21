require File.expand_path('../test_helper', __FILE__)

class EventTest < MiniTest::Unit::TestCase
  def setup
    stub_response(:put, fake_response(201, "Created", "class")) do
      Fauna::Class.create("henwen")
    end

    stub_response(:put, fake_response(201, "Created", "timeline")) do
      @timeline_ref = Fauna::TimelineSettings.create("comments")["resource"]["ref"]
    end

    stub_response(:post, fake_response(201, "Created", "instance")) do
      @event_ref = Fauna::Instance.create("henwen")["resource"]["ref"]
    end

    stub_response(:post, fake_response(201, "Created", "user")) do
      @resource_ref = Fauna::User.create(:name => "Taran", :email => "taran#{SecureRandom.hex}@example.com")["resource"]["ref"]
    end
  end

  def test_event_create
    stub_response(:post, fake_response(201, "Created", "timeline_events")) do
      response = Fauna::Event.create("#{@resource_ref}/#{@timeline_ref}", @event_ref)

      assert_match %r{users/\d+/timelines/comments}, response["resource"]["ref"]
      assert_equal "henwen", response["references"][@event_ref]["class"]
    end
  end

  def test_event_find
    stub_response(:post, fake_response(201, "Created", "timeline_events")) do
      Fauna::Event.create("#{@resource_ref}/#{@timeline_ref}", @event_ref)
    end

    stub_response(:get, fake_response(200, "OK", "timeline_events")) do
      response = Fauna::Event.find("#{@resource_ref}/#{@timeline_ref}")

      assert_match %r{users/\d+/timelines/comments}, response["resource"]["ref"]
      assert_equal "henwen", response["references"][@event_ref]["class"]
    end
  end

  def test_event_delete
    stub_response(:post, fake_response(201, "Created", "timeline_events")) do
      Fauna::Event.create("#{@resource_ref}/#{@timeline_ref}", @event_ref)
    end

    stub_response(:delete, fake_response(200, "OK", "timeline_events")) do
      response = Fauna::Event.delete("#{@resource_ref}/#{@timeline_ref}", @event_ref)

      assert_match %r{users/\d+/timelines/comments}, response["resource"]["ref"]
      assert_equal "henwen", response["references"][@event_ref]["class"]
    end
  end
end
