module Fauna
  module FaunaJson # :nodoc:
    def self.to_json(value)
      serialize(value).to_json
    end

    def self.to_json_pretty(value)
      JSON.pretty_generate serialize(value)
    end

    def self.deserialize(obj)
      if obj.is_a?(Hash)
        if obj.key? :@ref
          ref = obj[:@ref]
          id = ref[:id]

          if !ref.key?(:class) && !ref.key?(:database)
            Native.from_name(id)
          else
            cls = self.deserialize(ref[:class])
            db = self.deserialize(ref[:database])
            Ref.new(id, cls, db)
          end
        elsif obj.key? :@set
          SetRef.new deserialize(obj[:@set])
        elsif obj.key? :@obj
          deserialize(obj[:@obj])
        elsif obj.key? :@ts
          Time.iso8601 obj[:@ts]
        elsif obj.key? :@date
          Date.iso8601 obj[:@date]
        elsif obj.key? :@bytes
          Bytes.from_base64 obj[:@bytes]
        elsif obj.key? :@query
          QueryV.new deserialize(obj[:@query])
        else
          Hash[obj.collect { |k, v| [k, deserialize(v)] }]
        end
      elsif obj.is_a?(Array)
        obj.collect { |val| deserialize(val) }
      else
        obj
      end
    end

    def self.json_load(body)
      JSON.load body, nil, max_nesting: false, symbolize_names: true, create_additions: false
    end

    def self.json_load_or_nil(body)
      json_load body
    rescue JSON::ParserError
      nil
    end

    def self.serialize(value)
      if value.is_a? Time
        # 9 means: include nanoseconds in encoding
        { :@ts => value.iso8601(9) }
      elsif value.is_a? Date
        { :@date => value.iso8601 }
      elsif value.is_a? Hash
        Hash[value.collect { |k, v| [k, serialize(v)] }]
      elsif value.is_a? Array
        value.collect { |val| serialize(val) }
      elsif value.respond_to? :to_hash
        serialize(value.to_hash)
      else
        value
      end
    end
  end
end
