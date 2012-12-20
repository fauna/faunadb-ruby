require File.expand_path('../test_helper', __FILE__)

class TimelineSettingsTest < MiniTest::Unit::TestCase
  def test_timeline_create
    stub_response(:put, fake_response(201, "Created", "timeline")) do
      response = Fauna::TimelineSettings.create("comments")

      assert_equal "comments", response["resource"]["name"]
      assert_equal "timelines/comments", response["resource"]["ref"]
    end
  end

  def test_timeline_find_single
    stub_response(:put, fake_response(201, "Created", "timeline")) do
      Fauna::TimelineSettings.create("comments")

      stub_response(:get, fake_response(200, "OK", "timeline")) do
        response = Fauna::TimelineSettings.find("timelines/comments")

        assert_equal "comments", response["resource"]["name"]
        assert_equal "timelines/comments", response["resource"]["ref"]
      end
    end
  end

  def test_timeline_find_multiple
    stub_response(:put, fake_response(201, "Created", "timeline")) do
      Fauna::TimelineSettings.create("comments")

      stub_response(:get, fake_response(200, "OK", "timelines")) do
        response = Fauna::TimelineSettings.find("timelines")

        assert_equal "comments", response["resources"][0]["name"]
        assert_equal "timelines/comments", response["resources"][0]["ref"]
      end
    end
  end

  def test_timeline_delete
    stub_response(:put, fake_response(201, "Created", "timeline")) do
      Fauna::TimelineSettings.create("comments")

      stub_response(:delete, fake_response(200, "OK", nil)) do
        Fauna::TimelineSettings.delete("timelines/comments")

        stub_response(:get, fake_response(404, "Not Found", "timeline_deleted")) do
          begin
            Fauna::TimelineSettings.find("timelines/comments")
          rescue Exception => e
            assert_equal RestClient::ResourceNotFound, e.class
          end
        end
      end
    end
  end
end
