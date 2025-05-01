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

      def create = head(:method_not_allowed)
      def update = head(:method_not_allowed)

    private

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
