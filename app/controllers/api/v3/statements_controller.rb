module API
  module V3
    class StatementsController < BaseController
      def index
        conditions = { contract_period_years:, updated_since: }
        render json: to_json(paginate(statements_query(conditions:).statements))
      end

      def show
        render json: to_json(statements_query.statement_by_api_id(api_id))
      end

    private

      def statements_query(conditions: {})
        conditions[:lead_provider_id] = current_lead_provider.id
        Statements::Query.new(**conditions.compact)
      end

      def statement_params
        params.expect(:api_id)
      end

      def api_id
        statement_params[:api_id]
      end

      def to_json(obj)
        StatementSerializer.render(obj, root: "data")
      end
    end
  end
end
