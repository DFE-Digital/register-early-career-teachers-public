module AppropriateBodies
  module ProcessBatch
    # Management of closing induction periods in bulk via CSV upload
    class Action < Base
      # @return [nil, true] convert the valid submissions into permanent records
      def complete!
        pending_induction_submission_batch.completing!

        pending_induction_submission_batch.pending_induction_submissions.without_errors.map do |pending_induction_submission|
          @pending_induction_submission = pending_induction_submission

          record_outcome.pass! if pending_induction_submission.pass?
          record_outcome.fail! if pending_induction_submission.fail?
          release_ect.release! if pending_induction_submission.release?

          true
        rescue StandardError => e
          capture_error(e.message)
          next(false)
        end

        pending_induction_submission_batch.tally!
        pending_induction_submission_batch.completed!
        pending_induction_submission_batch.redact!
      end

    private

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
        elsif teacher
          if passed?
            capture_error("#{name} has already passed their induction")
            true
          elsif failed?
            capture_error("#{name} has already failed their induction")
            true
          elsif no_ongoing_induction_period?
            capture_error("#{name} does not have an open induction")
            true
          elsif claimed_by_another_ab?
            capture_error("#{name} is completing their induction with another appropriate body")
            true
          else
            false # can be claimed
          end
        elsif teacher.blank?
          capture_error("#{name} has not yet been claimed")
          true
        else
          false # can be claimed
        end
      end

      # @return [Boolean]
      def incorrectly_formatted?
        super

        pending_induction_submission.errors.add(:base, 'Outcome must be either pass, fail or release') if invalid_outcome?
        pending_induction_submission.errors.add(:base, 'Enter number of terms between 0 and 16 using up to one decimal place') if invalid_terms?

        pending_induction_submission.errors.any? ? pending_induction_submission.playback_errors : false
      end

      # @return [Boolean] pass, FAIL, Release (case-insensitive)
      def invalid_outcome?
        row.outcome !~ /\A(pass|fail|release)\z/i
      end

      # @return [Boolean] 0-16 upto one decimal place
      def invalid_terms?
        row.number_of_terms !~ /\A\d+(\.\d{1})?\z/ || !row.number_of_terms.to_f.between?(0, 16)
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
    end
  end
end
