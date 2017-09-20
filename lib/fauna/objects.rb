module Fauna
  ##
  # A Ref.
  #
  # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries#values-special_types]
  class Ref
    # The raw ref hash values.
    attr_accessor :value

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

      @value = { :id => id }
      @value[:class] = class_ unless class_.nil?
      @value[:database] = database unless database.nil?
    end

    ##
    # Gets the class part out of the Ref.
    def to_class
      value[:class]
    end

    ##
    # Gets the database part out of the Ref.
    def to_database
      value[:database]
    end

    ##
    # Gets the id part out of the Ref.
    def id
      value[:id]
    end

    # Converts the Ref to a string
    def to_s
      cls = to_class.nil? ? '' : ",class=#{to_class.to_s}"
      db = to_database.nil? ? '' : ",database=#{to_database.to_s}"
      "Ref(id=#{id}#{cls}#{db})"
    end

    # Converts the Ref in Hash form.
    def to_hash
      { :@ref => value }
    end

    # Returns +true+ if +other+ is a Ref and contains the same value.
    def ==(other)
      return false unless other.is_a? Ref
      value == other.value
    end

    alias_method :eql?, :==
  end

  class Native
    @classes = Ref.new('classes')
    @indexes = Ref.new('indexes')
    @databases = Ref.new('databases')
    @functions = Ref.new('functions')
    @keys = Ref.new('keys')
    @tokens = Ref.new('tokens')
    @credentials = Ref.new('credentials')

    def self.from_name(id)
      if id == 'classes'
        @classes
      elsif id == 'indexes'
        @indexes
      elsif id == 'databases'
        @databases
      elsif id == 'functions'
        @functions
      elsif id == 'keys'
        @keys
      elsif id == 'tokens'
        @tokens
      elsif id == 'credentials'
        @credentials
      else
        Ref.new id
      end
    end

    class << self
      attr_reader(:classes, :indexes, :databases, :functions, :keys, :tokens, :credentials)
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

    # Converts the SetRef to Hash form.
    def to_hash
      { :@set => value }
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

    # Converts the Bytes to Hash form.
    def to_hash
      { :@bytes => Base64.urlsafe_encode64(bytes) }
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

    # Converts the QueryV to Hash form.
    def to_hash
      { :@query => value }
    end

    # Returns +true+ if +other+ is a QueryV and contains the same value.
    def ==(other)
      return false unless other.is_a? QueryV
      value == other.value
    end

    alias_method :eql?, :==
  end
end
