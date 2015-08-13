module Fauna
  module Model
    class Page
      attr_reader :set, :params, :data, :before, :after

      def initialize(set, params, result)
        params.delete_if { |k, _| k == 'after' || k == 'before' }

        @set = set
        @params = params
        @data = result['data']
        @after = result['after']
        @before = result['before']
      end

      def next(params = {})
        create(set, self.params.merge('after' => after).merge(params))
      end

      def prev(params = {})
        create(set, self.params.merge('before' => before).merge(params))
      end

      def self.create(set, params = {})
        expression = Fauna::Query.paginate(set, params)

        result = Fauna::Context.query(expression)

        Page.new(set, params, result)
      end
    end
  end
end
