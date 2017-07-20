RSpec.describe Fauna::QueryV do
  describe '#==' do
    it 'equals same query' do
      lambda = Fauna::Query.expr { lambda_expr([:a], add(var(:a), var(:a))) }
      query = Fauna::QueryV.new(lambda)

      expect(query).to eq(Fauna::QueryV.new(lambda))
    end

    it 'does not equal different query' do
      lambda = Fauna::Query.expr { lambda_expr([:a], add(var(:a), var(:a))) }
      query = Fauna::QueryV.new(lambda)

      other_lambda = Fauna::Query.expr { lambda_expr([:b], multiply(var(:b), var(:b))) }
      expect(query).not_to eq(Fauna::QueryV.new(other_lambda))
    end

    it 'does not equal other type' do
      lambda = Fauna::Query.expr { lambda_expr([:a], add(var(:a), var(:a))) }
      query = Fauna::QueryV.new(lambda)

      expect(query).not_to eq(lambda)
    end
  end
end
