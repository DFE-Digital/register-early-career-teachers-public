module API
  module V3
    class SchoolsController < BaseController
      filter_validation required_filters: %i[cohort]

      def index
        render json: to_json(paginate(schools_query.schools))
      end

      def show
        render json: to_json(schools_query.school_by_api_id(api_id))
      end

    private

      def schools_query
        conditions = {
          lead_provider_id: current_lead_provider.id,
          contract_period_id: contract_period&.id,
          updated_since:,
          urn:,
          sort:,
        }

        Schools::Query.new(**conditions.compact)
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
        SchoolSerializer.render(obj, root: "data")
      end
    end
  end
end
