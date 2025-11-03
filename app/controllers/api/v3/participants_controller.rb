module API
  module V3
    class ParticipantsController < APIController
      include API::TeacherType

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

      def defer
        service = API::Teachers::Defer.new(
          lead_provider_id: current_lead_provider.id,
          teacher_api_id: teacher.api_id,
          reason: defer_participant_params[:reason],
          teacher_type:
        )

        respond_with_service(service:, action: :defer)
      end

      def resume
        validate_resume_participant_params!

        service = API::Teachers::Resume.new(
          lead_provider_id: current_lead_provider.id,
          teacher_api_id: teacher.api_id,
          teacher_type:
        )

        respond_with_service(service:, action: :resume)
      end

      def withdraw
        service = API::Teachers::Withdraw.new(
          lead_provider_id: current_lead_provider.id,
          teacher_api_id: teacher.api_id,
          reason: withdraw_participant_params[:reason],
          teacher_type:
        )

        respond_with_service(service:, action: :withdraw)
      end

    private

      def teachers_query(conditions: {})
        API::Teachers::Query.new(**(default_query_conditions.merge(conditions)).compact)
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id,
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

      def defer_participant_params
        params.require(:data).expect({ attributes: %i[reason] })
      end

      def resume_participant_params
        params.require(:data).expect({ attributes: %i[course_identifier] })
      end

      def validate_resume_participant_params! = resume_participant_params

      def withdraw_participant_params
        params.require(:data).expect({ attributes: %i[reason] })
      end

      def api_from_teacher_id
        participants_params.dig(:filter, :from_participant_id)
      end

      def training_status
        participants_params.dig(:filter, :training_status)
      end

      def teacher
        teachers_query.teacher_by_api_id(api_id)
      end

      def api_id
        participants_params[:api_id]
      end

      def sort
        sort_order(sort: participants_params[:sort], model: Teacher, default: { created_at: :asc })
      end

      def to_json(obj)
        API::TeacherSerializer.render(obj, root: "data", **serializer_options)
      end
    end
  end
end
