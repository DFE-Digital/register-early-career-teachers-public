module API
  module V3
    class StatementsController < APIController
      def index
        query_arguments = {
          contract_period_years: extract_conditions(contract_period_years, type: :integer),
          updated_since:,
        }
        paginated_statements = paginate(statements_query(query_arguments:).statements)

        render json: to_json(paginated_statements)
      end

      def show
        render json: to_json(statements_query.statement_by_api_id(api_id))
      end

    private

      def statements_query(query_arguments: {})
        API::Statements::Query.new(**(base_query_arguments.merge(query_arguments).compact))
      end

      def base_query_arguments
        {
          lead_provider_id: current_lead_provider.id,
          included_associations: serializer.dependencies
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
        API::StatementSerializer
      end
    end
  end
end
