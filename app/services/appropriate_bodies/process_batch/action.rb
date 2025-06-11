module AppropriateBodies
  module ProcessBatch
    # Management of closing induction periods in bulk via CSV upload
    class Action < Base
      # @return [Array<Boolean>] convert the valid submissions into permanent records
      def do!
        pending_induction_submission_batch.pending_induction_submissions.without_errors.map do |pending_induction_submission|
          @pending_induction_submission = pending_induction_submission

          do_action!
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

          next if fails_pre_checks?

          validate_submission!
        rescue StandardError => e
          capture_error(e.message)
          next
        end

      # Batch error reporting
      rescue StandardError => e
        pending_induction_submission_batch.update(error_message: e.message)
      end

    private

      # @return [Boolean]
      def do_action!
        PendingInductionSubmissionBatch.transaction do
          if pending_induction_submission.save(context: :record_outcome)
            record_outcome.pass! if pending_induction_submission.pass?
            record_outcome.fail! if pending_induction_submission.fail?
            true
          elsif pending_induction_submission.save(context: :release_ect)
            release_ect.release! if pending_induction_submission.outcome.nil?
            true
          else
            false
          end
        end
      end

      # @return [nil, Boolean]
      def validate_submission!
        pending_induction_submission.assign_attributes(
          finished_on: row.finished_on,
          number_of_terms: row.number_of_terms
        )

        case row.outcome
        when /fail/i
          pending_induction_submission.assign_attributes(outcome: 'fail')
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :record_outcome)
        when /pass/i
          pending_induction_submission.assign_attributes(outcome: 'pass')
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :record_outcome)
        when /release/i
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :release_ect)
        else
          pending_induction_submission.playback_errors
        end
      end

      # @return [Boolean]
      def fails_pre_checks?
        if incorrectly_formatted?
          true
        elsif (trs_error = fetch_trs_details!)
          capture_error(trs_error)
          true
        elsif teacher.blank?
          capture_error("#{name} has not yet been claimed")
          true
        elsif completed_induction_period?
          capture_error("#{name} has already completed their induction")
          true
        elsif ongoing_induction_period?
          capture_error("#{name} does not have an open induction")
          true
        elsif claimed_by_another_ab?
          capture_error("#{name} is completing their induction with another appropriate body")
          true
        else
          false
        end
      end

      # @return [Boolean]
      def incorrectly_formatted?
        pending_induction_submission.errors.add(:base, 'Fill in the blanks on this row') if row.blank_cell?
        pending_induction_submission.errors.add(:base, 'Dates must be in the format YYYY-MM-DD') if row.invalid_date?
        pending_induction_submission.errors.add(:base, 'Date of birth must be a real date and the teacher must be between 18 and 100 years old') if row.invalid_age?
        pending_induction_submission.errors.add(:base, 'Enter a valid TRN using 7 digits') if row.invalid_trn?
        pending_induction_submission.errors.add(:base, 'Outcome must be either pass, fail or release') if row.invalid_outcome?
        pending_induction_submission.errors.add(:base, 'Enter number of terms between 0 and 16 using up to one decimal place') if row.invalid_terms?

        pending_induction_submission.errors.any? ? pending_induction_submission.playback_errors : false
      end

      # @return [nil, Teacher]
      def teacher
        ::Teacher.find_by(trn: pending_induction_submission.trn)
      end

      # @return [nil, String]
      def name
        ::PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
      end

      # @return [Teachers::InductionPeriod]
      def induction_periods
        ::Teachers::InductionPeriod.new(teacher)
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
        'Prohibited from teaching'
      rescue TRS::Errors::QTSNotAwarded
        'QTS not awarded'
      rescue StandardError
        'Something went wrong. You’ll need to try again later'
      end

      # @return [Boolean]
      def ongoing_induction_period?
        induction_periods.ongoing_induction_period.blank?
      end

      # @return [Boolean]
      def completed_induction_period?
        induction_periods.last_induction_period&.outcome.present?
      end

      # @return [Boolean]
      def claimed_by_another_ab?
        appropriate_body != induction_periods.ongoing_induction_period&.appropriate_body
      end

      # @return [AppropriateBodies::ReleaseECT]
      def release_ect
        ReleaseECT.new(
          appropriate_body:,
          pending_induction_submission:,
          author:
        )
      end

      # @return [AppropriateBodies::RecordOutcome]
      def record_outcome
        RecordOutcome.new(
          appropriate_body:,
          pending_induction_submission:,
          teacher:,
          author:
        )
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
    end
  end
end
