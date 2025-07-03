module API
  module V3
    class StatementsController < BaseController
      include DateFilterable
      include ContractPeriodFilterable

      def index
        render json: to_json(paginate(statements_query.statements))
      end

      def show
        render json: to_json(statements_query.statement_by_api_id(api_id))
      end

    private

      def statements_query
        conditions = {
          lead_provider: current_lead_provider,
          contract_period_years:,
          updated_since:,
        }

        Statements::Query.new(**conditions.compact)
      end

      def statement_params
        params.permit(:api_id)
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
