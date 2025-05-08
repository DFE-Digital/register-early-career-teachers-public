module API
  module V3
    class ParticipantsController < BaseController
      include Pagination

      def index
        render json: to_json(paginate(participants_query.participants))
      end

      def show
        render json: to_json(participants_query.participant(id: participant_params[:id]))
      end

      def change_schedule = head(:method_not_allowed)
      def defer = head(:method_not_allowed)
      def resume = head(:method_not_allowed)
      def withdraw = head(:method_not_allowed)

    private

      def participants_query
        conditions = { lead_provider: current_lead_provider }

        Participants::Query.new(**conditions.compact)
      end

      def participant_params
        params.permit(:id)
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, root: "data", lead_provider: current_lead_provider)
      end
    end
  end
end
