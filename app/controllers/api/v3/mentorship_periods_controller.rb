module API
  module V3
    class MentorshipPeriodsController < APIController
      def index
        paginated_mentorship_periods = paginate(mentorship_periods_query.mentorship_periods)

        render json: to_json(paginated_mentorship_periods)
      end

    private

      def mentorship_periods_query
        MentorshipPeriods::Query.new(**default_query_conditions)
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id,
        }
      end

      def to_json(obj)
        API::MentorshipPeriodsSerializer.render(obj, root: "data")
      end
    end
  end
end
