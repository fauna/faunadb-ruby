module Fauna
  class Resource
    attr_reader :struct
    struct_reader :ref, :class

    def initialize(struct = {})
      @struct = struct
    end

    def ts
      Fauna.time_from_usecs(struct['ts']) unless struct['ts'].nil?
    end

  protected

    def self.struct_reader(*names)
      names.each do |name|
        define_method(name) do
          self.struct[name.to_s]
        end
      end
    end
  end

  class Database < Fauna::Resource
    struct_reader :name, :api_version, :data
  end

  class Key < Fauna::Resource
    struct_reader :database, :role, :data, :secret, :hashed_secret
  end

  class Class < Fauna::Resource
    struct_reader :name, :data, :history_days, :ttl_days, :permissions
  end

  class Instance < Fauna::Resource
    struct_reader :data
  end

  class Index < Fauna::Resource
    struct_reader :name, :source, :terms, :values, :unique, :permissions
  end
end
