module Fauna
  class Timeline
    def initialize(resource_ref, timeline_ref)
      @timeline_ref = "#{resource_ref}/#{timeline_ref}"
    end

    def add(ref)
      Fauna::Event.create(@timeline_ref, ref)
    end

    def remove(ref)
      Fauna::Event.delete(@timeline_ref, ref)
    end

    def events
      Fauna::Event.find(@timeline_ref)["references"]
    end
  end
end
