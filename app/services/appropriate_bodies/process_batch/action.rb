module AppropriateBodies
  module ProcessBatch
    # Pass / Fail / Release
    class Action < Base
      # @return [Array<?>] convert the valid submissions into permanent records
      def do!
        pending_induction_submission_batch.pending_induction_submissions.without_errors.map do |pending_induction_submission|
          @pending_induction_submission = pending_induction_submission

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

      # @return [CSV::Table] validate each row and create a submission capturing the errors
      def process!
        pending_induction_submission_batch.data.each do |row|
          @row = row

          PendingInductionSubmissionBatch.transaction do
            @pending_induction_submission = sparse_pending_induction_submission

            if (trs_error = fetch_trs_details!)
              pending_induction_submission.update(error_message: trs_error)
              next
            end

            if teacher.blank?
              pending_induction_submission.update(error_message: "Teacher #{name} has not yet been claimed")
              next
            end

            if claimed_by_another_ab?
              pending_induction_submission.update(error_message: "Teacher #{name} was claimed by a another appropriate body")
              next
            end

            process_row!
          end
        rescue StandardError => e
          pending_induction_submission.update(error_message: e.message)
          next
        end
      rescue StandardError => e
        pending_induction_submission_batch.update(error_message: e.message)
      end

    private

      def process_row!
        outcome = %w[pass fail].include?(row['objective']) ? row['objective'] : nil

        pending_induction_submission.assign_attributes(
          finished_on: row['end_date'],
          number_of_terms: row['number_of_terms'],
          outcome:
        )

        case row['objective']
        when 'fail', 'pass'
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :record_outcome)
        when 'release'
          pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :release_ect)
        end
      end

      # @return [nil, Teacher]
      def teacher
        ::Teacher.find_by(trn: pending_induction_submission.trn)
      end

      # @return [nil, String]
      def name
        PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
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

      def trs_teacher
        api_client.find_teacher(
          trn: pending_induction_submission.trn,
          date_of_birth: pending_induction_submission.date_of_birth
        )
      end

      def api_client
        @api_client ||= TRS::APIClient.new
      end

      # @return [nil, AppropriateBody]
      def teacher_active_appropriate_body
        ::Teachers::InductionPeriod.new(teacher).ongoing_induction_period&.appropriate_body
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

      def claimed_by_another_ab?
        teacher && teacher_active_appropriate_body && (appropriate_body != teacher_active_appropriate_body)
      end
    end
  end
end
