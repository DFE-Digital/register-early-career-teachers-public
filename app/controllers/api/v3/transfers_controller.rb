module API
  module V3
    class TransfersController < APIController
      def index
        filters = { updated_since:, sort: }
        paginated_school_transfers = paginate(lead_provider_school_transfers_query(filters:).school_transfers)

        render json: to_json(paginated_school_transfers)
      end

      def show
        render json: to_json(lead_provider_school_transfers_query.school_transfers_by_api_id(api_id))
      end

    private

      def lead_provider_school_transfers_query(filters: {})
        school_transfer_filters = lead_provider_filter.merge(filters).compact
        included_associations = { included_associations: serializer.dependencies }

        Teachers::SchoolTransfers::Query.new(**school_transfer_filters.merge(included_associations))
      end

      def lead_provider_filter
        { lead_provider_id: current_lead_provider.id }
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
        serializer.render(obj, root: "data", **lead_provider_filter)
      end

      def serializer
        API::Teachers::SchoolTransferSerializer
      end
    end
  end
end
