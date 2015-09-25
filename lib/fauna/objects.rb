module Fauna
  ##
  # A Ref.
  #
  # Reference: {FaunaDB Special Types}[https://faunadb.com/documentation/queries-values-special_types]
  class Ref
    # The raw ref string.
    attr_accessor :value

    ##
    # :call-seq:
    #   Ref.new('databases/prydain')
    #   Ref.new('databases', 'prydain')
    #   Ref.new(Ref.new('databases'), 'prydain')
    #
    # Creates a Ref object.
    #
    # +parts+: A string, or a list of strings/refs to be joined.
    def initialize(*parts)
      @value = parts.join '/'
    end

    ##
    # Gets the class part out of the Ref.
    # This is done by removing ref.id().
    # So <code>Fauna::Ref.new('a', 'b/c').to_class</code> will be
    # <code>Fauna::Ref.new('a/b')</code>.
    def to_class
      parts = value.split '/'
      if parts.length == 1
        self
      else
        Fauna::Ref.new(*parts[0...-1])
      end
    end

    ##
    # Removes the class part of the ref, leaving only the id.
    # This is everything after the last /.
    def id
      parts = value.split '/'
      fail FaunaError.new 'The Ref does not have an id.' if parts.length == 1
      parts.last
    end

    # Converts the Ref to a string
    def to_s
      value
    end

    # Converts the Ref in Hash form.
    def to_hash
      { '@ref' => value }
    end

    # Converts the Ref in JSON form.
    def to_json(*a)
      to_hash.to_json(*a)
    end

    # Returns +true+ if +other+ is a Ref and contains the same value.
    def ==(other)
      return false unless other.is_a? Ref
      value == other.value
    end

    alias_method :eql?, :==
  end

  ##
  # A Set.
  #
  # Reference: {FaunaDB Special Types}[https://faunadb.com/documentation/queries-values-special_types]
  class Set
    # The raw set hash.
    attr_accessor :value

    ##
    # Creates a new Set with the given parameters.
    #
    # +params+:: Hash of parameters to build the Set with.
    #
    # Reference: {FaunaDB Special Types}[https://faunadb.com/documentation/queries-values-special_types]
    def initialize(params = {})
      self.value = params
    end

    # Converts the Set to Hash form.
    def to_hash
      { '@set' => value }
    end

    # Converts the Set to JSON form.
    def to_json(*a)
      to_hash.to_json(*a)
    end

    # Returns +true+ if +other+ is a Set and contains the same value.
    def ==(other)
      return false unless other.is_a? Set
      value == other.value
    end

    alias_method :eql?, :==
  end

  ##
  # An Event.
  #
  # Reference: {FaunaDB Events}[https://faunadb.com/documentation/queries-values-events]
  class Event
    # The microsecond UNIX timestamp at which the event occurred.
    attr_accessor :ts
    # Either +create+ or +delete+.
    attr_accessor :action
    # The ref of the affected instance.
    attr_accessor :resource

    ##
    # Creates a new event
    #
    # +ts+:: Microsecond UNIX timestamp
    # +action+:: Either +create+ or +delete+. (Optional)
    # +resource+:: Ref of the affected instance. (Optional)
    def initialize(ts, action = nil, resource = nil)
      self.ts = ts
      self.action = action
      self.resource = resource
    end

    # Converts the Event to Hash form.
    def to_hash
      { 'ts' => ts, 'action' => action, 'resource' => resource }.delete_if { |_, value| value.nil? }
    end

    # Converts the Event to JSON form.
    def to_json(*a)
      to_hash.to_json(*a)
    end

    # Returns +true+ if +other+ is a Event and contains the same ts, action, and resource.
    def ==(other)
      return false unless other.is_a? Event
      ts == other.ts && action == other.action && resource == other.resource
    end

    alias_method :eql?, :==
  end
end
