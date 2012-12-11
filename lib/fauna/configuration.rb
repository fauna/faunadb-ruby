module Fauna
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end
  
  class Configuration
    attr_accessor :publisher_key, :username, :password
  end
end
