module API
  module V3
    class ParticipantsController < APIController
      def index
        render json: to_json(paginate(participants_query.participants))
      end

      def show = head(:method_not_allowed)
      def change_schedule = head(:method_not_allowed)
      def defer = head(:method_not_allowed)
      def resume = head(:method_not_allowed)
      def withdraw = head(:method_not_allowed)

    private

      def participants_query
        conditions = {}

        Participants::Query.new(**conditions.compact)
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, root: "data", lead_provider: current_lead_provider)
      end
    end
  end
end
