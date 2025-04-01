module AppropriateBodies
  module ProcessBatch
    class Base
      attr_reader :row,
                  :pending_induction_submission_batch,
                  :pending_induction_submission,
                  :appropriate_body,
                  :author

      def initialize(pending_induction_submission_batch:, author:)
        @pending_induction_submission_batch = pending_induction_submission_batch
        @author = author
        @appropriate_body = pending_induction_submission_batch.appropriate_body
      end

      # # @return [CSV::Table]
      # def process!
      #   pending_induction_submission_batch.data.each do |row|
      #     @row = row

      #     PendingInductionSubmissionBatch.transaction do
      #       @pending_induction_submission = sparse_pending_induction_submission

      #       # 1. Verify against TRS API
      #       # if (trs_error = fetch_trs_details!)
      #       #   pending_induction_submission.update(error_message: trs_error)
      #       #   next
      #       # end

      #       # 2. Verify record is claimed by the actioning AB
      #       # if claimed_by_another_ab?
      #       #   pending_induction_submission.update(error_message: "This teacher ain't yours!!")
      #       #   next
      #       # end

      #       # 3. Action object
      #       action_claim!
      #     end
      #   rescue AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB => e
      #     pending_induction_submission.update(error_message: e.message)
      #     next
      #   rescue AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithAnotherAB => e
      #     pending_induction_submission.update(error_message: e.message)
      #     next
      #   rescue TRS::Errors::TeacherNotFound
      #     pending_induction_submission.update(error_message: "Not found in TRS")
      #     next

      #   rescue TRS::Errors::ProhibitedFromTeaching
      #     pending_induction_submission.update(error_message: "Prohibited from teaching")
      #     next

      #   rescue TRS::Errors::QTSNotAwarded
      #     pending_induction_submission.update(error_message: "QTS not awarded")
      #     next

      #   rescue StandardError => e
      #     pending_induction_submission.update(error_message: e.message)
      #     next
      #   end
      # rescue StandardError => e
      #   pending_induction_submission_batch.update(error_message: e.message)
      # end

    private

      def debug(message)
        Rails.logger.debug "====================================================="
        Rails.logger.debug "#{message} - #{row['trn']} - #{row['objective']}"
        Rails.logger.debug "====================================================="
      end

      def sparse_pending_induction_submission
        ::PendingInductionSubmission.create(
          pending_induction_submission_batch:,
          appropriate_body:,
          trn: row['trn'],
          date_of_birth: Date.iso8601(row['dob'])
        )
      end
    end
  end
end
