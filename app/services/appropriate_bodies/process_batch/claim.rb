module AppropriateBodies
  module ProcessBatch
    # Management of registration and new induction periods in bulk via CSV upload
    class Claim < Base
      # @return [Array<Boolean>] convert the valid submissions into permanent records
      def complete!
        pending_induction_submission_batch.pending_induction_submissions.without_errors.map do |pending_induction_submission|
          @pending_induction_submission = pending_induction_submission

          register!
        rescue StandardError => e
          capture_error(e.message)
          next
        end

        # Batch error reporting
      rescue StandardError => e
        pending_induction_submission_batch.update(error_message: e.message)
      end

      # @return [nil] validate each row and create a submission capturing the errors
      def process!
        pending_induction_submission_batch.rows.each do |row|
          @row = row
          @pending_induction_submission = sparse_pending_induction_submission

          validate_submission!
        rescue Errors::TeacherHasActiveInductionPeriodWithCurrentAB
          capture_error('Already claimed by your appropriate body')
          next
        rescue Errors::TeacherHasActiveInductionPeriodWithAnotherAB
          capture_error('Already claimed by another appropriate body')
          next
        rescue ::TRS::Errors::TeacherNotFound
          capture_error('Not found in TRS')
          next
        rescue ::TRS::Errors::ProhibitedFromTeaching
          capture_error('Prohibited from teaching')
          next
        rescue ::TRS::Errors::QTSNotAwarded
          capture_error('QTS not awarded')
          next
        rescue StandardError => e
          capture_error(e.message)
          next
        end
      rescue StandardError => e
        capture_error(e.message)
      end

    private

      # @return [Boolean]
      def register!
        PendingInductionSubmissionBatch.transaction do
          if pending_induction_submission.save(context: :register_ect)
            # OPTIMIZE: params effectively passed in twice
            register_ect.register(
              started_on: pending_induction_submission.started_on,
              induction_programme: pending_induction_submission.induction_programme
            )
          else
            false
          end
        end
      end

      # @return [nil, Boolean]
      def validate_submission!
        pending_induction_submission.assign_attributes(
          started_on: row.started_on,
          induction_programme: row.induction_programme.downcase
        )

        # 1. check_if_teacher_has_ongoing_induction_period_with_appropriate_body!
        # 2. trs_teacher.check_eligibility!
        find_ect.import_from_trs!
        # 3. check_if_teacher_has_ongoing_induction_period_with_another_appropriate_body!
        check_ect.begin_claim!

        pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :find_ect) && pending_induction_submission.save(context: :check_ect) && pending_induction_submission.save(context: :register_ect)
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
