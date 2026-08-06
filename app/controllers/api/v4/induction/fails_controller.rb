module API
  module V4
    module Induction
      class FailsController < AppropriateBody::BaseController
        before_action :set_teacher
        before_action :set_induction_period

        def create
          AppropriateBodies::RecordFail.new(teacher: @teacher, appropriate_body_period:, author:)
            .call(**fail_params.to_h.symbolize_keys)

          render json: API::V4::InductionPeriodSerializer.render(@induction_period), status: :ok
        end

      private

        def set_teacher
          @teacher = AppropriateBodies::ECTs.new(appropriate_body_period).current.find_by!(trn: params[:trn])
        end

        def set_induction_period
          @induction_period = @teacher.ongoing_induction_period
        end

        def fail_params
          params.expect(fail: %i[finished_on number_of_terms fail_confirmation_sent_on])
        end
      end
    end
  end
end
