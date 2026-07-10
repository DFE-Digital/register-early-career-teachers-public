module API
  module V4
    class PartnershipsController < APIController
      def create
        service = SchoolPartnerships::Create.new({
          lead_provider_id: current_lead_provider.id,
          contract_period_year: create_partnership_params[:cohort],
          school_api_id: create_partnership_params[:school_id],
          delivery_partner_api_id: create_partnership_params[:delivery_partner_id],
        })

        respond_with_service(service:, action: :create)
      end

    private

      def create_partnership_params
        params.require(:data).expect({ attributes: %i[cohort school_id delivery_partner_id] })
      end

      def to_json(obj)
        API::SchoolPartnershipSerializer.render(obj, root: "data")
      end
    end
  end
end
