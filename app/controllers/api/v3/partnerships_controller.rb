module API
  module V3
    class PartnershipsController < BaseController
      include Pagination

      def index
        render json: to_json(paginate(partnerships_query.partnerships))
      end

      def show
        render json: to_json(partnerships_query.partnership(id: partnership_params[:id]))
      end

      def create
        service = SchoolPartnerships::Create.new(
          registration_year: declaration_params[:cohort],
          school_ecf_id: declaration_params[:school_id],
          delivery_partner_ecf_id: declaration_params[:delivery_partner_id],
          lead_provider_ecf_id: current_lead_provider.ecf_id
        )

        if service.valid?
          render json: to_json(service.create)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def update = head(:method_not_allowed)

    private

      def declaration_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:cohort, :school_id, :delivery_partner_id)
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def partnerships_query
        conditions = { lead_provider: current_lead_provider }

        Partnerships::Query.new(**conditions.compact)
      end

      def partnership_params
        params.permit(:id)
      end

      def to_json(obj)
        PartnershipSerializer.render(obj, root: "data")
      end
    end
  end
end
