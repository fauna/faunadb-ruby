module Fauna
  ##
  # Converts microseconds to a Time object.
  #
  # +microseconds+:: Time in microseconds.
  def self.time_from_usecs(microseconds)
    Time.at(microseconds / 1_000_000, microseconds % 1_000_000)
  end

  ##
  # Converts a Time object to microseconds.
  #
  # +time+:: A Time object.
  def self.usecs_from_time(time)
    time.to_i * 1_000_000 + time.usec
  end
end
