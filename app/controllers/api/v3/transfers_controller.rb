module API
  module V3
    class TransfersController < APIController
      def index
        conditions = { updated_since:, sort: }
        paginated_school_transfers = school_transfers_query(conditions:)
          .school_transfers { paginate(it) }

        render json: to_json(paginated_school_transfers)
      end

      def show
        render json: to_json(school_transfers_query.school_transfers_by_api_id(api_id))
      end

    private

      def school_transfers_query(conditions: {})
        conditions = default_query_conditions.merge(conditions).compact
        Teachers::SchoolTransfers::Query.new(**conditions)
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id
        }
      end

      def serializer_options
        @serializer_options ||= {
          lead_provider_id: current_lead_provider.id
        }
      end

      def school_transfers_params
        params.permit(:api_id, :sort)
      end

      def api_id
        school_transfers_params[:api_id]
      end

      def sort
        sort_order(
          sort: school_transfers_params[:sort],
          model: Teacher,
          default: { created_at: :asc }
        )
      end

      def to_json(obj)
        API::Teachers::SchoolTransferSerializer.render(
          obj,
          root: "data",
          **serializer_options
        )
      end

      def updated_at_attribute
        "api_updated_at"
      end
    end
  end
end
