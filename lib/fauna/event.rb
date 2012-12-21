module Fauna
  class Event < Resource
    def self.create(timeline_ref, event_ref)
      data = { :resource => event_ref }
      parse_response(connection.post("#{timeline_ref}", data))
    end

    def self.delete(timeline_ref, event_ref)
      data = { :resource => event_ref }
      parse_response(connection.delete("#{timeline_ref}", data))
    end

    class << self
      undef update
    end
  end
end
