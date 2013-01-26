require File.expand_path('../test_helper', __FILE__)

class TimelineSettingsTest < MiniTest::Unit::TestCase
  def test_timeline_create
    response = Fauna::TimelineSettings.create("comments")
    assert_equal "comments", response["resource"]["name"]
    assert_equal "timelines/comments", response["resource"]["ref"]
  end

  def test_timeline_find_single
    Fauna::TimelineSettings.create("comments")
    response = Fauna::TimelineSettings.find("timelines/comments")
    assert_equal "comments", response["resource"]["name"]
    assert_equal "timelines/comments", response["resource"]["ref"]
  end

  def test_timeline_find_multiple
    Fauna::TimelineSettings.create("comments")
    response = Fauna::TimelineSettings.find("timelines")
    assert_equal "comments", response["resources"][0]["name"]
    assert_equal "timelines/comments", response["resources"][0]["ref"]
  end

  def test_timeline_delete
    Fauna::TimelineSettings.create("comments")
    Fauna::TimelineSettings.delete("timelines/comments")
    begin
      Fauna::TimelineSettings.find("timelines/comments")
    rescue Exception => e
      assert_equal RestClient::ResourceNotFound, e.class
    end
  end
end
