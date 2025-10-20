module API
  module V3
    class StatementsController < APIController
      def index
        conditions = {
          contract_period_years: extract_conditions(contract_period_years),
          updated_since:
        }
        paginated_statements = statements_query(conditions:).statements { paginate(it) }

        render json: to_json(paginated_statements)
      end

      def show
        render json: to_json(statements_query.statement_by_api_id(api_id))
      end

      private

      def statements_query(conditions: {})
        API::Statements::Query.new(**default_query_conditions.merge(conditions).compact)
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id
        }
      end

      def statement_params
        params.permit(:api_id)
      end

      def api_id
        statement_params[:api_id]
      end

      def to_json(obj)
        API::StatementSerializer.render(obj, root: "data")
      end
    end
  end
end
