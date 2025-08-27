module API
  module V3
    class PartnershipsController < BaseController
      def index
        conditions = { contract_period_years:, updated_since:, delivery_partner_api_ids:, sort: }
        render json: to_json(paginate(partnerships_query(conditions:).school_partnerships))
      end

      def show
        render json: to_json(partnerships_query.school_partnership_by_api_id(api_id))
      end

      def create
        service = SchoolPartnerships::Create.new({
          lead_provider_id: current_lead_provider.id,
          contract_period_year: create_partnership_params[:cohort],
          school_api_id: create_partnership_params[:school_id],
          delivery_partner_api_id: create_partnership_params[:delivery_partner_id],
        })

        if service.valid?
          render json: to_json(service.create)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_content
        end
      end

      def update = head(:method_not_allowed)

    private

      def create_partnership_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:cohort, :school_id, :delivery_partner_id)
      end

      def partnerships_query(conditions: {})
        conditions[:lead_provider_id] = current_lead_provider.id
        SchoolPartnerships::Query.new(**conditions.compact)
      end

      def partnerships_params
        params.permit(:api_id, :sort, filter: %i[delivery_partner_id])
      end

      def api_id
        partnerships_params[:api_id]
      end

      def sort
        partnerships_params[:sort]
      end

      def delivery_partner_api_ids
        partnerships_params.dig(:filter, :delivery_partner_id)
      end

      def to_json(obj)
        PartnershipSerializer.render(obj, root: "data")
      end
    end
  end
end
