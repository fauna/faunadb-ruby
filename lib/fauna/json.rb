module Fauna
  module FaunaJson # :nodoc:
    @@serializable_types = [String, Numeric, TrueClass, FalseClass, NilClass, Hash, Array, Symbol, Time, Date, Fauna::Ref, Fauna::SetRef, Fauna::Bytes, Fauna::QueryV, Fauna::Query::Expr]

    def self.serializable_types
      @@serializable_types
    end

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

          if !ref.key?(:collection) && !ref.key?(:database) && !ref.key?(:class)
            Native.from_name(id)
          else
            source = ref[:collection] 
            source = ref[:class] if source.nil?
            coll = self.deserialize(source)
            db = self.deserialize(ref[:database])
            Ref.new(id, coll, db)
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
      # Handle primitives
      if [String, Numeric, TrueClass, FalseClass, NilClass].any? { |type| value.is_a? type }
        value
      elsif value.is_a? Hash
        Hash[value.collect { |k, v| [k, serialize(v)] }]
      elsif value.is_a? Array
        value.collect { |val| serialize(val) }
      elsif value.is_a? Symbol
        value.to_s
      # Natively supported types
      elsif value.is_a? Time
        # 9 means: include nanoseconds in encoding
        { :@ts => value.iso8601(9) }
      elsif value.is_a? Date
        { :@date => value.iso8601 }
      # Fauna native types
      elsif value.is_a? Ref
        ref = { id: value.id }
        ref[:collection] = value.collection unless value.collection.nil?
        ref[:database] = value.database unless value.database.nil?
        { :@ref => serialize(ref) }
      elsif value.is_a? SetRef
        { :@set => serialize(value.value) }
      elsif value.is_a? Bytes
        { :@bytes => value.to_base64 }
      elsif value.is_a? QueryV
        { :@query => serialize(value.value) }
      # Query expression wrapper
      elsif value.is_a? Query::Expr
        serialize(value.raw)
      # Everything else is rejected
      else
        fail SerializationError.new(value)
      end
    end
  end
end
