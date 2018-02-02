module Fauna
  module Deprecate
    ##
    # Deprecates a method
    #
    # class AClass
    #   extend Fauna::Deprecate
    #
    #   def method
    #   end
    #
    #   deprecate :method, :new_method
    #
    #   def new_method
    #   end
    # end
    #
    # +name+:: The method name to be deprecated
    # +replacement+:: The new method that should be used instead
    def deprecate(name, replacement)
      old_name = "deprecated_#{name}"
      alias_method old_name, name
      define_method name do |*args, &block|
        warn "Method #{name} called from #{Gem.location_of_caller.join(':')} is deprecated. Use #{replacement} instead"
        self.__send__ old_name, *args, &block
      end
    end
  end
end
