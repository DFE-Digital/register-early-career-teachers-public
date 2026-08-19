module API
  module V3
    class UnfundedMentorsController < APIController
      def index
        filters = { updated_since:, sort: }
        paginated_unfunded_mentors = paginate(lead_provider_unfunded_mentors_query(filters:).unfunded_mentors)

        render json: to_json(paginated_unfunded_mentors)
      end

      def show
        render json: to_json(lead_provider_unfunded_mentors_query.unfunded_mentor_by_api_id(api_id))
      end

    private

      def lead_provider_unfunded_mentors_query(filters: {})
        unfunded_mentor_filters = lead_provider_filter.merge(filters).compact
        included_associations = { included_associations: serializer.dependencies }

        API::Teachers::UnfundedMentors::Query.new(**unfunded_mentor_filters.merge(included_associations))
      end

      def lead_provider_filter
        { lead_provider_id: current_lead_provider.id }
      end

      def unfunded_mentor_params
        params.permit(:api_id, :sort)
      end

      def api_id
        unfunded_mentor_params[:api_id]
      end

      def sort
        sort_order(sort: unfunded_mentor_params[:sort], model: Teacher, default: { created_at: :asc })
      end

      def to_json(obj)
        serializer.render(obj, root: "data", **lead_provider_filter)
      end

      def serializer
        API::Teachers::UnfundedMentorSerializer
      end

      def updated_at_attribute
        "api_unfunded_mentor_updated_at"
      end
    end
  end
end
