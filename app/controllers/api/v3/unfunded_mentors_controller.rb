module API
  module V3
    class UnfundedMentorsController < APIController
      def index
        conditions = { updated_since:, sort: }
        paginated_unfunded_mentors = unfunded_mentors_query(conditions:).unfunded_mentors { paginate(it) }

        render json: to_json(paginated_unfunded_mentors)
      end

      def show
        render json: to_json(unfunded_mentors_query.unfunded_mentor_by_api_id(api_id))
      end

    private

      def unfunded_mentors_query(conditions: {})
        API::Teachers::UnfundedMentors::Query.new(**(default_query_conditions.merge(conditions).compact))
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id,
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

      def to_json(obj)
        API::Teachers::UnfundedMentorSerializer.render(obj, root: "data")
      end
    end
  end
end
