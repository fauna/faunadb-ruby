module Fauna
  class Class < Resource
    def self.update(class_name, data = {})
      parse_response(connection.put("classes/#{class_name}", data))
    end

    class << self
      alias_method :create, :update
    end

    def self.get_stats(ref)
      parse_response(connection.get("#{ref}/stats"))
    end
  end
end
