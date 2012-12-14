module Fauna
  class Instance < Resource
    def self.create(class_name)
      parse_response(connection.post("instances", { :class => class_name }))
    end

    def self.find(ref, class_name = nil, external_id = nil)
      query_params = []
      query_params << "class=#{class_name}" if class_name
      query_params << "external_id=#{external_id}" if external_id
      ref = ref + "?#{query_params.join("&")}" unless query_params.empty?
      parse_response(connection.get(ref))
    end
  end
end
