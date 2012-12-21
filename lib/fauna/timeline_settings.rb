module Fauna
  class TimelineSettings < Resource
    def self.update(timeline, data = {})
      parse_response(connection.put("timelines/#{timeline}", data))
    end

    class << self
      alias_method :create, :update
    end
  end
end
