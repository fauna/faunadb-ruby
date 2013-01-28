
module Fauna
  class Follow < Fauna::Model
    def self.find_by_follower_and_resource(follower, resource)
      find(new(:follower => follower, :resource => resource).ref)
    end

    def follower
      Fauna::Model.find(@__resource__.follower)
    end

    def resource
      Fauna::Model.find(@__resource__.resource)
    end

    def ref
      @__resource__.ref || (@__resource__.follower + "/follows/" + @__resource__.resource)
    end

    def update(*args)
      raise Fauna::Invalid, "Follows have nothing to update."
    end

    private

    def put
      Fauna::Client.put(ref, __resource__.to_hash)
    end

    def follower=(resource)
      @__resource__.follower = resource.ref
    end

    def resource=(resource)
      @__resource__.resource = resource.ref
    end

    alias :post :put
  end
end
