module API
  module V3
    class SchoolsController < BaseController
      filter_validation required_filters: %i[cohort]

      def index
        conditions = { updated_since:, urn:, sort: }
        render json: to_json(paginate(schools_query(conditions:).schools))
      end

      def show
        render json: to_json(schools_query.school_by_api_id(api_id))
      end

    private

      def schools_query(conditions: {})
        API::Schools::Query.new(**(default_conditions.merge(conditions)).compact)
      end

      def default_conditions
        @default_conditions ||= {
          contract_period_year: contract_period.year,
          lead_provider_id: current_lead_provider.id,
        }
      end

      def school_params
        params.permit(:api_id, :sort, filter: %i[urn])
      end

      def api_id
        school_params[:api_id]
      end

      def sort
        school_params[:sort]
      end

      def urn
        school_params.dig(:filter, :urn)
      end

      def to_json(obj)
        API::SchoolSerializer.render(obj, root: "data", **default_conditions)
      end
    end
  end
end
