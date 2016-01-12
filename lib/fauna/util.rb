module Fauna
  ##
  # Converts microseconds to a Time object.
  #
  # +microseconds+:: Time in microseconds.
  def self.time_from_usecs(microseconds)
    Time.at(microseconds / 1_000_000, microseconds % 1_000_000)
  end

  ##
  # Converts a Time object to microseconds.
  #
  # +time+:: A Time object.
  def self.usecs_from_time(time)
    time.to_i * 1_000_000 + time.usec
  end

  # :nodoc:
  class DSLContext
    # :nodoc:
    def self.eval_dsl(dsl, &blk)
      ctx = eval('self', blk.binding)
      dsl.instance_variable_set(:@__ctx__, ctx)

      ctx.instance_variables.each do |iv|
        dsl.instance_variable_set(iv, ctx.instance_variable_get(iv))
      end

      dsl.instance_exec(&blk)

    ensure
      dsl.instance_variables.each do |iv|
        if iv.to_sym != :@__ctx__
          ctx.instance_variable_set(iv, dsl.instance_variable_get(iv))
        end
      end
    end

    NON_PROXIED_METHODS = Set.new %w(__send__ object_id __id__ == equal?
                                    ! != instance_exec instance_variables
                                    instance_variable_get instance_variable_set
                                  ).map(&:to_sym)

    instance_methods.each do |method|
      undef_method(method) unless NON_PROXIED_METHODS.include?(method.to_sym)
    end

    def method_missing(method, *args, &block)
      @__ctx__.send(method, *args, &block)
    end
  end
end
