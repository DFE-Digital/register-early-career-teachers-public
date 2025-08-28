module API
  module V3
    class StatementsController < BaseController
      def index
        conditions = { contract_period_years:, updated_since: }
        paginated_statements = paginate(statements_query(conditions:).statements)
        statements = serializer.preload_query(paginated_statements)

        render json: to_json(statements)
      end

      def show
        render json: to_json(statements_query.statement_by_api_id(api_id))
      end

    private

      def statements_query(conditions: {})
        Statements::Query.new(**(default_query_conditions.merge(conditions).compact))
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id,
        }
      end

      def statement_params
        params.permit(:api_id)
      end

      def api_id
        statement_params[:api_id]
      end

      def to_json(obj)
        serializer.render(obj, root: "data")
      end

      def serializer
        StatementSerializer
      end
    end
  end
end
