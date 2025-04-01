module AppropriateBodies
  module ProcessBatch
    # Claim
    class Claim < Base
      # @return [CSV::Table]
      def process!
        pending_induction_submission_batch.data.each do |row|
          @row = row

          PendingInductionSubmissionBatch.transaction do
            @pending_induction_submission = sparse_pending_induction_submission

            pending_induction_submission.assign_attributes(
              started_on: row['start_date'],
              induction_programme: row['induction_programme'].downcase
            )

            find_ect.import_from_trs!
            check_ect.begin_claim!
            register_ect.register(
              started_on: row['start_date'],
              induction_programme: row['induction_programme'].downcase
            )
          end
        rescue ::AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB => e
          pending_induction_submission.update(error_message: e.message)
          next
        rescue ::AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithAnotherAB => e
          pending_induction_submission.update(error_message: e.message)
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

      def find_ect
        ClaimAnECT::FindECT.new(appropriate_body:, pending_induction_submission:)
      end

      def check_ect
        ClaimAnECT::CheckECT.new(appropriate_body:, pending_induction_submission:)
      end

      def register_ect
        ClaimAnECT::RegisterECT.new(appropriate_body:, pending_induction_submission:, author:)
      end
    end
  end
end
