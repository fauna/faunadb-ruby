module Fauna
  ##
  # A Ref.
  #
  # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries#values-special_types]
  class Ref
    # The raw ref string.
    attr_accessor :value

    ##
    # Creates a Ref object.
    #
    # :call-seq:
    #   Ref.new('databases/prydain')
    #
    # +value+: A string.
    def initialize(value)
      @value = value
    end

    ##
    # Gets the class part out of the Ref.
    # This is done by removing ref.id().
    # So <code>Fauna::Ref.new('a/b/c').to_class</code> will be
    # <code>Fauna::Ref.new('a/b')</code>.
    def to_class
      parts = value.split '/'
      if parts.length == 1
        self
      else
        Fauna::Ref.new(parts[0...-1].join('/'))
      end
    end

    ##
    # Removes the class part of the ref, leaving only the id.
    # This is everything after the last /.
    def id
      parts = value.split '/'
      fail ArgumentError.new 'The Ref does not have an id.' if parts.length == 1
      parts.last
    end

    # Converts the Ref to a string
    def to_s
      value
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
  # A QueryF.
  #
  # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries-values-special_types]
  class QueryF
    # The raw query hash.
    attr_accessor :value

    ##
    # Creates a new QueryF with the given parameters.
    #
    # +params+:: Hash of parameters to build the QueryF with.
    #
    # Reference: {FaunaDB Special Types}[https://fauna.com/documentation/queries-values-special_types]
    def initialize(params = {})
      self.value = params
    end

    # Converts the QueryF to Hash form.
    def to_hash
      { :@query => value }
    end

    # Returns +true+ if +other+ is a QueryF and contains the same value.
    def ==(other)
      return false unless other.is_a? QueryF
      value == other.value
    end

    alias_method :eql?, :==
  end
end
