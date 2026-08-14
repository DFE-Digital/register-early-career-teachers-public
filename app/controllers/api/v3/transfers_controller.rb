module API
  module V3
    class TransfersController < APIController
      def index
        query_arguments = { updated_since:, sort: }
        paginated_school_transfers = paginate(school_transfers_query(query_arguments:).school_transfers)

        render json: to_json(paginated_school_transfers)
      end

      def show
        render json: to_json(school_transfers_query.school_transfers_by_api_id(api_id))
      end

    private

      def school_transfers_query(query_arguments: {})
        query_arguments = base_query_arguments.merge(query_arguments).compact
        Teachers::SchoolTransfers::Query.new(**query_arguments)
      end

      def base_query_arguments
        {
          lead_provider_id: current_lead_provider.id,
          included_associations: serializer.dependencies
        }
      end

      def serializer_options
        {
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
        serializer.render(obj, root: "data", **serializer_options)
      end

      def serializer
        API::Teachers::SchoolTransferSerializer
      end
    end
  end
end
