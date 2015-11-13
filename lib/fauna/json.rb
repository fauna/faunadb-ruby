module Fauna
  # This is for internal use only.
  module FaunaJson
    # :nodoc:
    def self.to_json(value)
      to_hash(value).to_json
    end

    # :nodoc:
    def self.to_json_pretty(value)
      JSON.pretty_generate to_hash(value)
    end

    # :nodoc:
    def self.deserialize(obj)
      if obj.is_a?(Hash)
        if obj.key? :@ref
          Ref.new obj[:@ref]
        elsif obj.key? :@set
          Set.new deserialize(obj[:@set])
        elsif obj.key? :@obj
          deserialize(obj[:@obj])
        elsif obj.key? :@ts
          Time.iso8601 obj[:@ts]
        elsif obj.key? :@date
          Date.iso8601 obj[:@date]
        else
          Hash[obj.collect { |k, v| [k, deserialize(v)] }]
        end
      elsif obj.is_a?(Array)
        obj.collect { |val| deserialize(val) }
      else
        obj
      end
    end

    # :nodoc:
    def self.json_load(body)
      JSON.load body, nil, max_nesting: false, symbolize_names: true
    end

    # :nodoc:
    def self.to_hash(value)
      if value.is_a? Time
        # 9 means: include nanoseconds in encoding
        { :@ts => value.iso8601(9) }
      elsif value.is_a? Date
        { :@date => value.iso8601 }
      else
        value.to_hash
      end
    end
    private_class_method :to_hash
  end
end
