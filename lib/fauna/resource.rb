module Fauna
  ##
  # Base wrapper class for FaunaDB resources.
  class Resource
    ##
    # The FaunaDB resource that is being wrapped.
    attr_reader :struct

    ##
    # The ref for the FaunaDB resource.
    # :attr_reader: ref

    ##
    # The class for the FaunaDB resource.
    # :attr_reader: class

    ##
    # The timestamp for the FaunaDB resource.
    # :attr_reader: ts

    struct_reader :ref, :class

    ##
    # Create a wrapper around a FaunaDB resource.
    #
    # Takes a resource from FaunaDB as a hash.
    def initialize(struct = {})
      @struct = struct
    end

    def ts
      Fauna.time_from_usecs(struct['ts']) unless struct['ts'].nil?
    end

    class << self
    protected

      ##
      # Creates readers for top level resource elements.
      def self.struct_reader(*names)
        names.each do |name|
          define_method(name) do
            struct[name.to_s]
          end
        end
      end
    end
  end

  ##
  # Wrapper for a database resource.
  class Database < Fauna::Resource
    ##
    # The name of the database.
    # :attr_reader: name

    ##
    # The default api version used when making requests to the database.
    # :attr_reader: api_version

    ##
    # The user-defined data for the database.
    # :attr_reader: data

    struct_reader :name, :api_version, :data
  end

  ##
  # Wrapper for a key resource.
  class Key < Fauna::Resource
    ##
    # The database the key is associated with.
    # :attr_reader: database

    ##
    # The role of the key.
    # :attr_reader: role

    ##
    # The user-defined data for the key.
    # :attr_reader: data

    ##
    # The secret for the key. Only returned upon creation.
    # :attr_reader: secret

    ##
    # A hashed version of the key.
    # :attr_reader: hashed_secret

    struct_reader :database, :role, :data, :secret, :hashed_secret
  end

  ##
  # Wrapper for a class resource.
  class Class < Fauna::Resource
    ##
    # The name of the class.
    # :attr_reader: name

    ##
    # The user-defined data for the class.
    # :attr_reader: data

    ##
    # How many days instance history is held for.
    # :attr_reader: history_days

    ##
    # How many days since last write before instances are deleted.
    # :attr_reader: ttl_days

    ##
    # The permissions for the class.
    # :attr_reader: permissions

    struct_reader :name, :data, :history_days, :ttl_days, :permissions
  end

  ##
  # Wrapper for a instance resource.
  class Instance < Fauna::Resource
    ##
    # The user-defined data for the instance.
    # :attr_reader: data

    struct_reader :data
  end

  ##
  # Wrapper for a index resource.
  class Index < Fauna::Resource
    ##
    # The name of the index.
    # :attr_reader: name

    ##
    # The class to be indexed.
    # :attr_reader: source

    ##
    # The fields to be indexed.
    # :attr_reader: terms

    ##
    # The fields to be covered.
    # :attr_reader: values

    ##
    # If the index is unique or not.
    # :attr_reader: unique

    ##
    # The permissions for the index.
    # :attr_reader: permissions

    struct_reader :name, :source, :terms, :values, :unique, :permissions
  end
end
