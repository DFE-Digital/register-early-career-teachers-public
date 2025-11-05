module AppropriateBodies
  module ProcessBatch
    class Base
      attr_reader :row,
                  :pending_induction_submission_batch,
                  :pending_induction_submission,
                  :appropriate_body_period,
                  :author

      def initialize(pending_induction_submission_batch:, author:)
        @pending_induction_submission_batch = pending_induction_submission_batch
        @author = author
        @appropriate_body_period = pending_induction_submission_batch.appropriate_body_period
      end

      # @return [true] validate each row and create a submission capturing the errors
      def process!
        pending_induction_submission_batch.processing!

        pending_induction_submission_batch.rows.each do |row|
          @row = row
          @pending_induction_submission = sparse_pending_induction_submission

          next if fails_pre_checks?

          validate_submission!
        rescue StandardError => e
          Rails.logger.info(e.message)
          Sentry.capture_exception(e)
          capture_error("Something went wrong. You’ll need to try again later")

          next
        end

        pending_induction_submission_batch.processed!
      end

    private

      # Formatting validation of TRN and DOB happens after creation so a safe version of the TRN is used
      # @return [PendingInductionSubmission]
      def sparse_pending_induction_submission
        ::PendingInductionSubmission.find_or_create_by(
          pending_induction_submission_batch:,
          appropriate_body_period:,
          trn: row.sanitised_trn,
          date_of_birth: row.date_of_birth
        )
      end

      # @return [Boolean] common pre-checks for all submissions
      def incorrectly_formatted?
        pending_induction_submission.errors.add(:base, "Fill in the blanks on this row") if row.blank_cell?
        pending_induction_submission.errors.add(:base, "Enter a valid TRN using 7 digits") if row.invalid_trn?
        pending_induction_submission.errors.add(:base, "Dates must be in the format YYYY-MM-DD") if row.invalid_date?
        pending_induction_submission.errors.add(:base, "Date of birth must be a real date and the teacher must be between 18 and 100 years old") if row.invalid_age?
        pending_induction_submission.errors.add(:base, "Dates cannot be in the future") if row.future_dates?
      end

      # @param message [String]
      # @return [Boolean]
      def capture_error(message)
        pending_induction_submission.update(error_messages: [message])
      end

      # @return [nil, String]
      def name
        ::PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
      end

      # @return [nil, Teacher]
      def teacher
        ::Teacher.find_by(trn: pending_induction_submission.trn)
      end

      # @return [Boolean]
      def claimed_by_another_ab?
        teacher.ongoing_induction_period.present? &&
          teacher.current_appropriate_body_period != appropriate_body_period
      end

      # @return [Boolean]
      def no_ongoing_induction_period?
        teacher.ongoing_induction_period.blank?
      end

      # @return [Boolean]
      def passed?
        teacher.last_induction_period&.outcome.eql?("pass")
      end

      # @return [Boolean]
      def failed?
        teacher.last_induction_period&.outcome.eql?("fail")
      end

      # @return [TRS::Teacher]
      # @raise [TRS::Errors::TeacherNotFound]
      # @raise [TRS::Errors::TeacherDeactivated]
      # @raise [TRS::Errors::TeacherMerged]
      # @raise [TRS::Errors::APIRequestError]
      def trs_teacher
        api_client.find_teacher(
          trn: pending_induction_submission.trn,
          date_of_birth: pending_induction_submission.date_of_birth
        )
      end

      # @return [TRS::APIClient]
      def api_client
        @api_client ||= ::TRS::APIClient.build
      end

      # @return [nil, String]
      def fetch_trs_details!
        pending_induction_submission.update(**trs_teacher.to_h)

        nil
      rescue TRS::Errors::TeacherNotFound,
             TRS::Errors::TeacherDeactivated,
             TRS::Errors::TeacherMerged
        "TRN and date of birth do not match"
      rescue TRS::Errors::APIRequestError
        "TRS could not be contacted. You’ll need to try again later"
      end

      def track_analytics!
        AnalyticsBatchJob.perform_later(pending_induction_submission_batch_id: pending_induction_submission_batch.id)
      end
    end
  end
end
