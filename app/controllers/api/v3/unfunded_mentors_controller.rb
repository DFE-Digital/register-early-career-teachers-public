module API
  module V3
    class UnfundedMentorsController < APIController
      def index
        query_arguments = { updated_since:, sort: }
        paginated_unfunded_mentors = paginate(unfunded_mentors_query(query_arguments:).unfunded_mentors)

        render json: to_json(paginated_unfunded_mentors)
      end

      def show
        render json: to_json(unfunded_mentors_query.unfunded_mentor_by_api_id(api_id))
      end

    private

      def unfunded_mentors_query(query_arguments: {})
        API::Teachers::UnfundedMentors::Query.new(**(base_query_arguments.merge(query_arguments).compact))
      end

      def base_query_arguments
        {
          lead_provider_id: current_lead_provider.id,
          included_associations: serializer.dependencies
        }
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

      def serializer_options
        @serializer_options ||= { lead_provider_id: current_lead_provider.id }
      end

      def to_json(obj)
        serializer.render(obj, root: "data", **serializer_options)
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
