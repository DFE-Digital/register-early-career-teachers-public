module API
  module V4
    module Induction
      class ClaimsController < AppropriateBody::BaseController
        rescue_from TRS::Errors::TeacherNotFound,
                    TRS::Errors::TeacherDeactivated,
                    TRS::Errors::TeacherMerged,
                    with: :not_found_response

        rescue_from AppropriateBodies::ClaimAnECT::CheckECT::TeacherHasOngoingInductionPeriodWithAnotherAB,
                    AppropriateBodies::ClaimAnECT::FindECT::TeacherHasOngoingInductionPeriodWithCurrentAB do |exception|
          render json: { errors: API::Errors::Response.new(title: "Conflict", messages: exception.message).call }, status: :conflict
        end

        rescue_from TRS::Errors::ProhibitedFromTeaching,
                    TRS::Errors::InductionAlreadyCompleted,
                    TRS::Errors::QTSNotAwarded do |exception|
          render json: { errors: API::Errors::Response.new(title: "Unprocessable", messages: exception.message).call }, status: :unprocessable_content
        end

        def create
          return render_submission_errors unless find_ect.import_from_trs!

          check_ect.begin_claim!

          if register.register(**claim_params.to_h.symbolize_keys)
            render json: API::V4::InductionPeriodSerializer.render(register.induction_period), status: :created
          else
            render_submission_errors
          end
        end

      private

        def submission
          @submission ||= PendingInductionSubmission.new(
            trn: params[:trn],
            date_of_birth: claim_params[:date_of_birth],
            appropriate_body_period_id: appropriate_body_period.id
          )
        end

        def find_ect
          AppropriateBodies::ClaimAnECT::FindECT.new(appropriate_body_period:, pending_induction_submission: submission)
        end

        def check_ect
          AppropriateBodies::ClaimAnECT::CheckECT.new(appropriate_body_period:, pending_induction_submission: submission)
        end

        def register
          @register ||= AppropriateBodies::ClaimAnECT::RegisterECT.new(appropriate_body_period:, pending_induction_submission: submission, author:)
        end

        def claim_params
          params.expect(claim: %i[date_of_birth started_on training_programme])
        end

        def render_submission_errors
          render json: API::Errors::Response.from(submission), status: :unprocessable_content
        end
      end
    end
  end
end
