module API
  module V4
    module Induction
      class PassesController < AppropriateBody::BaseController
        before_action :set_teacher
        before_action :set_induction_period

        def create
          AppropriateBodies::RecordPass.new(teacher: @teacher, appropriate_body_period:, author:)
            .call(**pass_params.to_h.symbolize_keys)

          render json: API::V4::InductionPeriodSerializer.render(@induction_period), status: :ok
        end

      private

        def set_teacher
          @teacher = AppropriateBodies::ECTs.new(appropriate_body_period).current.find_by!(trn: params[:trn])
        end

        def set_induction_period
          @induction_period = @teacher.ongoing_induction_period
        end

        def pass_params
          params.expect(pass: %i[finished_on number_of_terms])
        end
      end
    end
  end
end
