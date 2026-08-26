module API
  module V3
    class StatementsController < ActionController::API
      include API::TokenAuthenticatable
      include API::Paginatable
      include API::ErrorRescuable
      include API::DateFilterable
      include API::ContractPeriodFilterable
      include API::FilterValidatable
      include API::Orderable
      include API::ConditionExtractable
      include API::Analyticable

      def index
        filters = {
          contract_period_years: extract_conditions(contract_period_years, type: :integer),
          updated_since:,
        }
        paginated_statements = paginate(lead_provider_statements_query(filters:).statements)

        render json: to_json(paginated_statements)
      end

      def show
        render json: to_json(lead_provider_statements_query.statement_by_api_id(api_id))
      end

    private

      def lead_provider_statements_query(filters: {})
        statement_filters = { lead_provider_id: current_lead_provider.id }.merge(filters).compact
        included_associations = { included_associations: serializer.dependencies }

        API::Statements::Query.new(**statement_filters.merge(included_associations))
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
