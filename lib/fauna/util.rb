module Fauna
  def self.stringify_keys!(hash)
    hash.keys.each do |k|
      self[key.to_s] = self.delete(k)
    end
  end

  def self.stringify_keys(hash)
    stringify_keys!(hash.dup)
  end
end
