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

      # @return [true] validate each row and create a submission capturing the errors
      def process!
        pending_induction_submission_batch.processing!

        pending_induction_submission_batch.rows.each do |row|
          @row = row
          @pending_induction_submission = sparse_pending_induction_submission

          next if fails_pre_checks?

          validate_submission!
        rescue StandardError => e
          capture_error(e.message)
          next
        end

        pending_induction_submission_batch.processed!
      end

      # @return [Boolean] valid submissions are still valid
      def revalidated?
        pending_induction_submission_batch.pending_induction_submissions.without_errors.all? do |pending_induction_submission|
          @row = pending_induction_submission_batch.row_by(trn: pending_induction_submission.trn)
          @pending_induction_submission = pending_induction_submission

          next(false) if fails_pre_checks?

          validate_submission!.nil?
        end
      end

    private

      # Formatting validation of TRN and DOB happens after creation so a safe version of the TRN is used
      # @return [PendingInductionSubmission]
      def sparse_pending_induction_submission
        ::PendingInductionSubmission.find_or_create_by(
          pending_induction_submission_batch:,
          appropriate_body:,
          trn: row.sanitised_trn,
          date_of_birth: row.date_of_birth
        )
      end

      # @return [Boolean] common pre-checks for all submissions
      def incorrectly_formatted?
        pending_induction_submission.errors.add(:base, 'Fill in the blanks on this row') if row.blank_cell?
        pending_induction_submission.errors.add(:base, 'Enter a valid TRN using 7 digits') if row.invalid_trn?
        pending_induction_submission.errors.add(:base, 'Dates must be in the format YYYY-MM-DD') if row.invalid_date?
        pending_induction_submission.errors.add(:base, 'Date of birth must be a real date and the teacher must be between 18 and 100 years old') if row.invalid_age?
        pending_induction_submission.errors.add(:base, 'Dates cannot be in the future') if row.future_dates?
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

      # @return [Teachers::InductionPeriod]
      def induction_periods
        ::Teachers::InductionPeriod.new(teacher)
      end

      # @return [Boolean]
      def claimed_by_another_ab?
        return false unless induction_periods.ongoing_induction_period

        appropriate_body != induction_periods.ongoing_induction_period.appropriate_body
      end

      # @return [TRS::Teacher]
      # @raise [TRS::Errors::TeacherNotFound]
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
        pending_induction_submission.update(
          **trs_teacher.present.except(:trs_national_insurance_number)
        )

        nil
      rescue TRS::Errors::TeacherNotFound
        'TRN and date of birth do not match'
      rescue TRS::Errors::ProhibitedFromTeaching
        "#{name} is prohibited from teaching"
      rescue TRS::Errors::QTSNotAwarded
        "#{name} does not have their qualified teacher status (QTS)"
      rescue StandardError
        "Something went wrong. You’ll need to try again later"
      end

      def fails_pre_checks?
        raise(NotImplementedError)
      end
    end
  end
end
