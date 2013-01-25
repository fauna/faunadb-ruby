module Fauna
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :publisher_key, :username, :password, :logger, :log_response

    def initialize
      if ENV["FAUNA_DEBUG"] or ENV["FAUNA_DEBUG_RESPONSE"]
        @logger = Logger.new(STDERR)
        if ENV["FAUNA_DEBUG_RESPONSE"]
          @log_response = true
        end
      end
    end
  end
end
