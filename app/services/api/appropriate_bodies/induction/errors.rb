module API
  module AppropriateBodies
    class Induction
      module Errors
        extend ActiveSupport::Concern
        include ActiveSupport::Rescuable

        class Error < StandardError; end
        class TeacherNotFound < Error; end
        class AlreadyClaimed < Error; end
        class NotEligible < Error; end
        class TRSUnavailable < Error; end

        class Invalid < Error
          attr_reader :errors

          def initialize(errors)
            @errors = errors
            super(errors.map(&:full_message).to_sentence)
          end
        end

        CLAIM_ATTRIBUTES = %i[trn date_of_birth started_on training_programme].freeze

        included do
          rescue_from TRS::Errors::TeacherNotFound, TRS::Errors::TeacherDeactivated, TRS::Errors::TeacherMerged do
            raise TeacherNotFound, "Nothing could be found for the provided details"
          end

          rescue_from ::AppropriateBodies::ClaimAnECT::FindECT::TeacherHasOngoingInductionPeriodWithCurrentAB do
            raise AlreadyClaimed, "The teacher already has an ongoing induction period with this appropriate body"
          end

          rescue_from ::AppropriateBodies::ClaimAnECT::CheckECT::TeacherHasOngoingInductionPeriodWithAnotherAB do
            raise AlreadyClaimed, "The teacher has an ongoing induction period with another appropriate body"
          end

          rescue_from TRS::Errors::ProhibitedFromTeaching do
            raise NotEligible, "The teacher is prohibited from teaching"
          end

          rescue_from TRS::Errors::InductionAlreadyCompleted do
            raise NotEligible, "The teacher has already completed their induction"
          end

          rescue_from TRS::Errors::QTSNotAwarded do
            raise NotEligible, "The teacher has not been awarded QTS"
          end

          rescue_from TRS::Errors::APIRequestError, Faraday::Error do
            raise TRSUnavailable, "The Teaching Record System is unavailable. Try again later."
          end
        end

      private

        def claim_errors(pending_induction_submission:)
          errors = pending_induction_submission.errors
          errors.select { it.attribute.in?(CLAIM_ATTRIBUTES) }.presence || [errors.add(:base, "The claim could not be registered")]
        end
      end
    end
  end
end
