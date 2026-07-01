module API
  module V3
    class MentoringMentorsController < APIController
      def index
        conditions = { updated_since:, sort: }
        paginated_mentoring_mentors = paginate(mentoring_mentors_query(conditions:).mentoring_mentors)

        render json: to_json(paginated_mentoring_mentors)
      end

      def show
        render json: to_json(mentoring_mentors_query.mentoring_mentor_by_api_id(api_id))
      end

    private

      def mentoring_mentors_query(conditions: {})
        API::Teachers::MentoringMentors::Query.new(**(default_query_conditions.merge(conditions).compact))
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id,
        }
      end

      def mentoring_mentor_params
        params.permit(:api_id, :sort)
      end

      def api_id
        mentoring_mentor_params[:api_id]
      end

      def sort
        sort_order(sort: mentoring_mentor_params[:sort], model: Teacher, default: { created_at: :asc })
      end

      def serializer_options
        @serializer_options ||= { lead_provider_id: current_lead_provider.id }
      end

      def to_json(obj)
        API::Teachers::MentoringMentorSerializer.render(obj, root: "data", **serializer_options)
      end

      def updated_at_attribute
        "api_updated_at"
      end
    end
  end
end
