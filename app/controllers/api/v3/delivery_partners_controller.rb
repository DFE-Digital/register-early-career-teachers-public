module API
  module V3
    class DeliveryPartnersController < APIController
      def index
        query_arguments = {
          contract_period_years: extract_conditions(contract_period_years, type: :integer),
          sort:,
        }
        paginated_delivery_partners = paginate(delivery_partners_query(query_arguments:).delivery_partners)

        render json: to_json(paginated_delivery_partners)
      end

      def show
        render json: to_json(delivery_partners_query.delivery_partner_by_api_id(api_id))
      end

    private

      def delivery_partners_query(query_arguments: {})
        API::DeliveryPartners::Query.new(**(base_query_arguments.merge(query_arguments)).compact)
      end

      def base_query_arguments
        {
          lead_provider_id: current_lead_provider.id,
          included_associations: serializer.dependencies,
        }
      end

      def serializer_options
        {
          lead_provider_id: current_lead_provider.id
        }
      end

      def delivery_partner_params
        params.permit(:api_id, :sort)
      end

      def api_id
        delivery_partner_params[:api_id]
      end

      def sort
        sort_order(sort: delivery_partner_params[:sort], model: DeliveryPartner, default: { created_at: :asc })
      end

      def to_json(obj)
        serializer.render(obj, root: "data", **serializer_options)
      end

      def serializer
        API::DeliveryPartnerSerializer
      end
    end
  end
end
