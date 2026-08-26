module API
  module V3
    class DeliveryPartnersController < ActionController::API
      include API::TokenAuthenticatable
      include API::Paginatable
      include API::ErrorRescuable
      include API::ContractPeriodFilterable
      include API::Orderable
      include API::ConditionExtractable
      include API::Analyticable

      def index
        filters = {
          contract_period_years: extract_conditions(contract_period_years, type: :integer),
          sort:,
        }
        paginated_delivery_partners = paginate(lead_provider_declarations_query(filters:).delivery_partners)

        render json: to_json(paginated_delivery_partners)
      end

      def show
        render json: to_json(lead_provider_declarations_query.delivery_partner_by_api_id(api_id))
      end

    private

      def lead_provider_declarations_query(filters: {})
        delivery_partner_filters = lead_provider_filter.merge(filters).compact
        included_associations = { included_associations: serializer.dependencies }

        API::DeliveryPartners::Query.new(**delivery_partner_filters.merge(included_associations))
      end

      def lead_provider_filter
        { lead_provider_id: current_lead_provider.id }
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
        serializer.render(obj, root: "data", **lead_provider_filter)
      end

      def serializer
        API::DeliveryPartnerSerializer
      end
    end
  end
end
