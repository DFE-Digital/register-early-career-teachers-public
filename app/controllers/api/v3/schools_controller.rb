module API
  module V3
    class SchoolsController < APIController
      filter_validation required_filters: %i[cohort]

      def index
        filters = { updated_since:, urn:, sort: }.compact
        paginated_schools = paginate(lead_provider_schools_query(filters:).schools)

        render json: to_json(paginated_schools)
      end

      def show
        render json: to_json(lead_provider_schools_query.school_by_api_id(api_id))
      end

    private

      def lead_provider_schools_query(filters: {})
        school_filters = lead_provider_and_contract_period_filters.merge(filters)
        included_associations = { included_associations: serializer.dependencies }

        API::Schools::Query.new(**school_filters.merge(included_associations))
      end

      def lead_provider_and_contract_period_filters
        {
          lead_provider_id: current_lead_provider.id,
          contract_period_year: contract_period&.year
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
        serializer.render(obj, root: "data", **lead_provider_and_contract_period_filters)
      end

      def serializer
        API::SchoolSerializer
      end
    end
  end
end
