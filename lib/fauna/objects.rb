module Fauna
  ##
  # A Ref.
  #
  # Reference: {FaunaDB Special Types}[https://faunadb.com/documentation#queries-values-special_types]
  class Ref
    # The raw ref string.
    attr_accessor :value

    ##
    # Creates a Ref object from a string.
    #
    # +ref+:: A ref in string form.
    def initialize(ref)
      self.value = ref
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
  end

  ##
  # A Set.
  #
  # Reference: {FaunaDB Special Types}[https://faunadb.com/documentation#queries-values-special_types]
  class Set
    # The match term.
    attr_accessor :match
    # The index Ref the match is made on.
    attr_accessor :index

    ##
    # Creates a new Set from a match term and index ref.
    #
    # +match+:: The match term.
    # +index+:: The index Ref the match is made on.
    #
    # Reference: {FaunaDB Special Types}[https://faunadb.com/documentation#queries-values-special_types]
    def initialize(match, index)
      self.match = match
      self.index = index
    end

    # Converts the Set to Hash form.
    def to_hash
      { '@set' => { 'match' => match, 'index' => index.to_hash } }
    end

    # Converts the Set to JSON form.
    def to_json(*a)
      to_hash.to_json(*a)
    end
  end

  ##
  # An Event.
  #
  # Reference: {FaunaDB Events}[https://faunadb.com/documentation#queries-values-events]
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
  end
end
