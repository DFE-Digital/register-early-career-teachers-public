module API
  module V3
    class DeliveryPartnersController < BaseController
      def index
        conditions = { contract_period_years:, sort: }
        render json: to_json(paginate(delivery_partners_query(conditions:).delivery_partners))
      end

      def show
        render json: to_json(delivery_partners_query.delivery_partner_by_api_id(api_id))
      end

    private

      def delivery_partners_query(conditions: {})
        conditions[:lead_provider] = current_lead_provider
        DeliveryPartners::Query.new(**conditions.compact)
      end

      def delivery_partner_params
        params.permit(:api_id, :sort)
      end

      def api_id
        delivery_partner_params[:api_id]
      end

      def sort
        delivery_partner_params[:sort]
      end

      def to_json(obj)
        DeliveryPartnerSerializer.render(obj, root: "data", lead_provider: current_lead_provider)
      end
    end
  end
end
