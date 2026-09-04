module API
  module V3
    class MentorshipPeriodsController < ActionController::API
      include API::TokenAuthenticatable
      include API::Paginatable
      include API::Orderable
      include API::ErrorRescuable
      include API::Analyticable

      def index
        filters = {
          sort:,
          ect_api_id: mentorship_period_params.dig(:filter, :ect_participant_id),
          mentor_api_id: mentorship_period_params.dig(:filter, :mentor_participant_id),
          school_urn: mentorship_period_params.dig(:filter, :school_urn)
        }
        paginated_mentorship_periods = paginate(mentorship_periods_query(filters:).mentorship_periods)

        render json: to_json(paginated_mentorship_periods)
      end

    private

      def mentorship_periods_query(filters:)
        mentorship_period_filters = lead_provider_filter.merge(filters).compact
        included_associations = { included_associations: serializer.dependencies }

        API::MentorshipPeriods::Query.new(**mentorship_period_filters.merge(included_associations))
      end

      def lead_provider_filter
        { lead_provider_id: current_lead_provider.id }
      end

      def sort
        sort_order(sort: mentorship_period_params[:sort], model: MentorshipPeriod, default: { created_at: :desc })
      end

      def mentorship_period_params
        params.permit(:sort, filter: %i[ect_participant_id mentor_participant_id school_urn])
      end

      def to_json(obj)
        serializer.render(obj, root: "data", **lead_provider_filter)
      end

      def serializer
        API::MentorshipPeriodsSerializer
      end
    end
  end
end
