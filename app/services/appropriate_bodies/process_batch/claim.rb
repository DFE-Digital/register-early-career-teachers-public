module AppropriateBodies
  module ProcessBatch
    # Claim
    class Claim < Base
      # @return [CSV::Table]
      def process!
        pending_induction_submission_batch.rows.each do |row|
          @row = row
          @pending_induction_submission = sparse_pending_induction_submission

          claim!
        rescue Errors::TeacherHasActiveInductionPeriodWithCurrentAB
          pending_induction_submission.update(error_message: "Already claimed by your appropriate body")
          next
        rescue Errors::TeacherHasActiveInductionPeriodWithAnotherAB
          pending_induction_submission.update(error_message: "Already claimed by another appropriate body")
          next
        rescue ::TRS::Errors::TeacherNotFound
          pending_induction_submission.update(error_message: "Not found in TRS")
          next
        rescue ::TRS::Errors::ProhibitedFromTeaching
          pending_induction_submission.update(error_message: "Prohibited from teaching")
          next
        rescue ::TRS::Errors::QTSNotAwarded
          pending_induction_submission.update(error_message: "QTS not awarded")
          next
        rescue StandardError => e
          pending_induction_submission.update(error_message: e.message)
          next
        end
      rescue StandardError => e
        pending_induction_submission_batch.update(error_message: e.message)
      end

    private

      # @return [?]
      def claim!
        PendingInductionSubmissionBatch.transaction do
          pending_induction_submission.assign_attributes(
            started_on: row.start_date,
            induction_programme: row.induction_programme.downcase
          )

          find_ect.import_from_trs!
          check_ect.begin_claim!

          if pending_induction_submission.save(context: :register_ect)
            # OPTIMIZE: params effectively passed in twice
            register_ect.register(
              started_on: pending_induction_submission.started_on,
              induction_programme: pending_induction_submission.induction_programme
            )
          else
            pending_induction_submission.playback_errors
          end
        end
      end

      # @return [AppropriateBodies::ClaimAnECT::FindECT]
      def find_ect
        ClaimAnECT::FindECT.new(appropriate_body:, pending_induction_submission:)
      end

      # @return [AppropriateBodies::ClaimAnECT::CheckECT]
      def check_ect
        ClaimAnECT::CheckECT.new(appropriate_body:, pending_induction_submission:)
      end

      # @return [AppropriateBodies::ClaimAnECT::RegisterECT]
      def register_ect
        ClaimAnECT::RegisterECT.new(appropriate_body:, pending_induction_submission:, author:)
      end
    end
  end
end
