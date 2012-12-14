module Fauna
  class Resource
    private_class_method :new

    def self.find(ref)
      parse_response(connection.get(ref))
    end

    def self.update(ref, data = {})
      parse_response(connection.put(ref, data))
    end

    def self.delete(ref)
      connection.delete(ref)
    end

    def self.connection
      @connection ||= Connection.new(:publisher_key => Fauna.configuration.publisher_key)
    end

    def self.connection=(connection)
      @connection = connection
    end

    protected

    def self.parse_response(response)
      JSON.parse(response.to_str)
    end
  end
end
