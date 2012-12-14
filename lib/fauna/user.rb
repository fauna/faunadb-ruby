module Fauna
  class User < Resource
    def self.create(data = {})
      parse_response(connection.post("users", data))
    end

    def self.get_stats(ref)
      parse_response(connection.get("#{ref}/stats"))
    end
  end
end
