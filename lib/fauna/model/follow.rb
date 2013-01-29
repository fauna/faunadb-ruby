
module Fauna
  class Follow < Fauna::Model
    def self.find_by_follower_and_resource(follower, resource)
      find(new(:follower => follower, :resource => resource).ref)
    end

    def initialize(attrs = {})
      super({})
      attrs.stringify_keys!
      follower_ref = attrs['follower_ref']
      follower_ref = attrs['follower'].ref if attrs['follower']
      resource_ref = attrs['resource_ref']
      resource_ref = attrs['resource'].ref if attrs['resource']
      ref = "#{follower_ref}/follows/#{resource_ref}"

      raise ArgumentError, "Follower ref is nil." if follower_ref.nil?
      raise ArgumentError, "Resource ref is nil." if resource_ref.nil?

      @struct = { 'ref' => ref, 'follower' => follower_ref, 'resource' => resource_ref }
    end

    def follower_ref
      struct['follower']
    end

    def follower
      Fauna::Client.find(follower_ref)
    end

    def resource_ref
      struct['resource']
    end

    def resource
      Fauna::Client.find(resource_ref)
    end

    def update(*args)
      raise Fauna::Invalid, "Follows have nothing to update."
    end
  end
end
