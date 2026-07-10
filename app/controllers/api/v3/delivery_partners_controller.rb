module API
  module V3
    class DeliveryPartnersController < APIController
      def index
        conditions = {
          contract_period_years: extract_conditions(contract_period_years, type: :integer),
          sort:
        }
        delivery_partners = delivery_partners_query(conditions:).delivery_partners
        paginated_delivery_partners = paginate(serializer.preload_associations(delivery_partners))

        render json: to_json(paginated_delivery_partners)
      end

      def show
        # TODO: pass in a preloader so the query service can call it before find_by!
        delivery_partner = delivery_partners_query.delivery_partner_by_api_id(api_id)
        delivery_partner.strict_loading!(false)

        render json: to_json(delivery_partner)
      end

    private

      def delivery_partners_query(conditions: {})
        API::DeliveryPartners::Query.new(**(default_query_conditions.merge(conditions)).compact)
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id,
        }
      end

      def serializer_options
        @serializer_options ||= {
          lead_provider_id: current_lead_provider.id,
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
        API::V3::DeliveryPartnerSerializer
      end
    end
  end
end
