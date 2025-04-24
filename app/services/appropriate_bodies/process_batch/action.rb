module AppropriateBodies
  module ProcessBatch
    # Management of induction periods in bulk via CSV upload
    # Handles Pass / Fail / Release in two stages
    class Action < Base
      # @return [Array<?>] convert the valid submissions into permanent records
      def do!
        pending_induction_submission_batch.pending_induction_submissions.without_errors.map do |pending_induction_submission|
          @pending_induction_submission = pending_induction_submission

          do_action!
        end
      end

      # @return [CSV::Table] validate each row and create a submission capturing the errors
      def process!
        pending_induction_submission_batch.rows.each do |row|
          @row = row
          @pending_induction_submission = sparse_pending_induction_submission

          if incorrectly_formatted?
            next
          end

          if (trs_error = fetch_trs_details!)
            capture_error(trs_error)
            next
          end

          if teacher.blank?
            capture_error("Teacher #{name} has not yet been claimed")
            next
          end

          if ongoing_induction_period.blank?
            capture_error("Teacher #{name} does not have an ongoing induction")
            next
          end

          if claimed_by_another_ab?
            capture_error("Teacher #{name} was claimed by another appropriate body")
            next
          end

          validate_submission!
        rescue StandardError => e
          capture_error(e.message)
          next
        end
      rescue StandardError => e
        capture_error(e.message)
      end

    private

      # @return [?]
      def do_action!
        PendingInductionSubmissionBatch.transaction do
          if pending_induction_submission.save(context: :record_outcome)
            record_outcome.pass! if pending_induction_submission.pass?
            record_outcome.fail! if pending_induction_submission.fail?

          elsif pending_induction_submission.save(context: :release_ect)

            release_ect.release! if pending_induction_submission.outcome.nil? # needs work - why not add "release" to the enum?
          else
            false
          end
        end
      end

      # @return [?]
      def validate_submission!
        pending_induction_submission.assign_attributes(
          finished_on: row.end_date,
          number_of_terms: row.number_of_terms
        )

        case row.objective
        when /fail/i
          pending_induction_submission.assign_attributes(outcome: 'fail')
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :record_outcome)
        when /pass/i
          pending_induction_submission.assign_attributes(outcome: 'pass')
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :record_outcome)
        when /release/i
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :release_ect)
        else
          pending_induction_submission.errors.add(:outcome, "Objective must be pass, fail or release")
          pending_induction_submission.playback_errors
        end
      end

      # @return [Boolean]
      def incorrectly_formatted?
        pending_induction_submission.errors.add(:base, 'Fill in the blanks') if row.blank_cell?
        pending_induction_submission.errors.add(:base, 'Dates must be in the format YYYY-MM-DD') if row.invalid_date?
        pending_induction_submission.errors.add(:base, 'Teacher reference number must be 7 digits') if row.invalid_trn?
        pending_induction_submission.errors.add(:base, 'Outcome must be either pass, fail or release') if row.invalid_outcome?
        pending_induction_submission.errors.add(:base, 'Number of terms must be between 0 and 16. You can use up to one decimal place') if row.invalid_terms?

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

      # @return [nil, String]
      def fetch_trs_details!
        pending_induction_submission.update(
          **trs_teacher.present.except(:trs_national_insurance_number)
        )

        nil
      rescue TRS::Errors::TeacherNotFound
        "Not found in TRS"
      rescue TRS::Errors::ProhibitedFromTeaching
        "Prohibited from teaching"
      rescue TRS::Errors::QTSNotAwarded
        "QTS not awarded"
      rescue StandardError
        "TRS API could not be contacted"
      end

      # @return [nil, InductionPeriod]
      def ongoing_induction_period
        ::Teachers::InductionPeriod.new(teacher).ongoing_induction_period
      end

      # @return [Boolean]
      def claimed_by_another_ab?
        teacher && ongoing_induction_period && (appropriate_body != ongoing_induction_period.appropriate_body)
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
        @api_client ||= ::TRS::APIClient.new
      end
    end
  end
end
