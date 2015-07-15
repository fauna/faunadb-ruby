module Fauna
  class Ref
    attr_accessor :ref

    def initialize(ref)
      self.ref = ref
    end

    def to_class
      if ref.start_with?('classes')
        Ref.new(ref.split('/', 3)[0..1].join('/'))
      else
        Ref.new(ref.split('/', 2).first)
      end
    end

    def to_s
      self.ref
    end

    def to_hash
      { '@ref' => self.ref }
    end

    def to_json(*a)
      to_hash.to_json(*a)
    end
  end

  class Set
    attr_accessor :match, :index

    def initialize(match, index)
      self.match = match
      self.index = index
    end

    def to_hash
      { '@set' => { 'match' => self.match, 'index' => self.index } }
    end

    def to_json(*a)
      to_hash.to_json(*a)
    end
  end

  class Obj < Hash
    def to_hash
      { '@obj' => self.to_hash }
    end

    def to_json(*a)
      to_hash.to_json(*a)
    end
  end

  class Event
    attr_accessor :ts, :action, :resource

    def initialize(ts, action, resource)
      self.ts = ts
      self.action = action
      self.resource = resource
    end

    def to_hash
      { 'ts' => self.ts, 'action' => self.action, 'resource' => self.resource }.delete_if { |_, value| value.nil? }
    end

    def to_json(*a)
      to_hash.to_json(*a)
    end
  end
end
