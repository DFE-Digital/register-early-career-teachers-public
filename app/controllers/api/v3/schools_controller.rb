module API
  module V3
    class SchoolsController < APIController
      filter_validation required_filters: %i[cohort]

      def index
        query_arguments = { updated_since:, urn:, sort: }
        paginated_schools = paginate(schools_query(query_arguments:).schools)

        render json: to_json(paginated_schools)
      end

      def show
        render json: to_json(schools_query.school_by_api_id(api_id))
      end

    private

      def schools_query(query_arguments: {})
        API::Schools::Query.new(**(base_query_arguments.merge(query_arguments.compact)))
      end

      def base_query_arguments
        {
          contract_period_year: contract_period&.year,
          lead_provider_id: current_lead_provider.id,
          included_associations: serializer.dependencies
        }
      end

      def serializer_options
        {
          contract_period_year: contract_period&.year,
          lead_provider_id: current_lead_provider.id
        }
      end

      def school_params
        params.permit(:api_id, :sort, filter: %i[urn])
      end

      def api_id
        school_params[:api_id]
      end

      def sort
        sort_order(sort: school_params[:sort], model: sort_model, default: { created_at: :asc })
      end

      def sort_model
        school_params[:sort]&.include?("updated_at") ? Metadata::SchoolContractPeriod : School
      end

      def urn
        school_params.dig(:filter, :urn)
      end

      def to_json(obj)
        serializer.render(obj, root: "data", **serializer_options)
      end

      def serializer
        API::SchoolSerializer
      end
    end
  end
end
