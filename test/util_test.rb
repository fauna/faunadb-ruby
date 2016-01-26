require File.expand_path('../test_helper', __FILE__)

class UtilTest < FaunaTest
  def test_time_from_usecs
    assert_equal Time.at(1, 234_567), Fauna.time_from_usecs(1_234_567)
  end

  def test_usecs_from_time
    assert_equal 1_234_567, Fauna.usecs_from_time(Time.at(1, 234_567))
  end
end
