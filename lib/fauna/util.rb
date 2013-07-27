module Fauna
  def self.stringify_keys!(hash)
    hash.keys.each do |k|
      hash[k.to_s] = hash.delete k
    end
  end

  def self.stringify_keys(hash)
    stringify_keys!(hash.dup)
  end

  def self.time_from_usecs(microseconds)
    Time.at(microseconds/1_000_000, microseconds % 1_000_000)
  end

  def self.usecs_from_time(time)
    time.to_i * 1000000 + time.usec
  end
end
