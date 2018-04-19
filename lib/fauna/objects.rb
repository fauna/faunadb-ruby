module Fauna
  ##
  # A Ref.
  #
  # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries#values-special_types]
  class Ref
    # The raw attributes of ref.
    attr_accessor :id, :class_, :database

    ##
    # Creates a Ref object.
    #
    # :call-seq:
    #   Ref.new('prydain', Native.databases)
    #
    # +id+: A string.
    # +class_+: A Ref.
    # +database+: A Ref.
    def initialize(id, class_ = nil, database = nil)
      fail ArgumentError.new 'id cannot be nil' if id.nil?

      @id = id
      @class_ = class_ unless class_.nil?
      @database = database unless database.nil?
    end

    # Converts the Ref to a string
    def to_s
      cls = class_.nil? ? '' : ",class=#{class_.to_s}"
      db = database.nil? ? '' : ",database=#{database.to_s}"
      "Ref(id=#{id}#{cls}#{db})"
    end

    # Returns +true+ if +other+ is a Ref and contains the same value.
    def ==(other)
      return false unless other.is_a? Ref
      id == other.id && class_ == other.class_ && database == other.database
    end

    alias_method :eql?, :==
  end

  class Native
    @@natives = %w(classes indexes databases functions keys tokens credentials).freeze

    @@natives.each do |id|
      instance_variable_set "@#{id}", Ref.new(id).freeze
      self.class.send :attr_reader, id.to_sym
    end

    def self.from_name(id)
      return Ref.new(id) unless @@natives.include? id
      send id.to_sym
    end
  end

  ##
  # A SetRef.
  #
  # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries#values-special_types]
  class SetRef
    # The raw set hash.
    attr_accessor :value

    ##
    # Creates a new SetRef with the given parameters.
    #
    # +params+:: Hash of parameters to build the SetRef with.
    #
    # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries#values-special_types]
    def initialize(params = {})
      self.value = params
    end

    # Returns +true+ if +other+ is a SetRef and contains the same value.
    def ==(other)
      return false unless other.is_a? SetRef
      value == other.value
    end

    alias_method :eql?, :==
  end

  ##
  # A Bytes wrapper.
  #
  # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries#values-special_types]
  class Bytes
    # The raw bytes.
    attr_accessor :bytes

    ##
    # Creates a new Bytes wrapper with the given parameters.
    #
    # +bytes+:: The bytes to be wrapped by the Bytes object.
    #
    # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries#values-special_types]
    def initialize(bytes)
      self.bytes = bytes
    end

    # Converts the Bytes to base64-encoded form.
    def to_base64
      Base64.urlsafe_encode64(bytes)
    end

    # Returns +true+ if +other+ is a Bytes and contains the same bytes.
    def ==(other)
      return false unless other.is_a? Bytes
      bytes == other.bytes
    end

    alias_method :eql?, :==

    # Create new Bytes object from Base64 encoded bytes.
    def self.from_base64(enc)
      new(Base64.urlsafe_decode64(enc))
    end
  end

  ##
  # A QueryV.
  #
  # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries-values-special_types]
  class QueryV
    # The raw query hash.
    attr_accessor :value

    ##
    # Creates a new QueryV with the given parameters.
    #
    # +params+:: Hash of parameters to build the QueryV with.
    #
    # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries-values-special_types]
    def initialize(params = {})
      self.value = params
    end

    # Returns +true+ if +other+ is a QueryV and contains the same value.
    def ==(other)
      return false unless other.is_a? QueryV
      value == other.value
    end

    alias_method :eql?, :==
  end
end
