module API
  module V3
    class ParticipantsController < APIController
      def index
        conditions = {
          contract_period_years: extract_conditions(contract_period_years, integers: true),
          updated_since:,
          training_status:,
          api_from_teacher_id:,
          sort:
        }
        paginated_teachers = teachers_query(conditions:).teachers { paginate(it) }

        render json: to_json(paginated_teachers)
      end

      def show
        render json: to_json(teachers_query.teacher_by_api_id(api_id))
      end

      def change_schedule = head(:method_not_allowed)
      def defer = head(:method_not_allowed)
      def resume = head(:method_not_allowed)
      def withdraw = head(:method_not_allowed)

      private

      def teachers_query(conditions: {})
        API::Teachers::Query.new(**default_query_conditions.merge(conditions).compact)
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id
        }
      end

      def serializer_options
        @serializer_options ||= {
          lead_provider_id: current_lead_provider.id
        }
      end

      def participants_params
        params.permit(:api_id, :sort, filter: %i[training_status from_participant_id])
      end

      def api_from_teacher_id
        participants_params.dig(:filter, :from_participant_id)
      end

      def training_status
        participants_params.dig(:filter, :training_status)
      end

      def api_id
        participants_params[:api_id]
      end

      def sort
        sort_order(sort: participants_params[:sort], model: Teacher, default: {created_at: :asc})
      end

      def to_json(obj)
        API::TeacherSerializer.render(obj, root: "data", **serializer_options)
      end
    end
  end
end
