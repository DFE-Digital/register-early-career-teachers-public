module AppropriateBodies
  class ProcessBatch
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

    # Pass / Fail / Release
    # @return [CSV::Table]
    def process!
      pending_induction_submission_batch.data.each do |row|
        # begin
        @row = row

        # PendingInductionSubmissionBatch.transaction do
        @pending_induction_submission = sparse_pending_induction_submission

        # 1. Verify against TRS API
        if trs_error = fetch_trs_details!
          pending_induction_submission.update(error_message: trs_error)
          next
        end

        # 2. Verify record is claimed by the actioning AB
        if claimed_by_another_ab?
          pending_induction_submission.update(error_message: "This teacher ain't yours!!")
          next
        end

        # 3. Action object
        case row['objective']
        when 'fail', 'pass' then action_outcome!
        when 'release'      then action_release!
        else
          next
        end

        # end
      rescue StandardError => e
        pending_induction_submission.update(error_message: e.message)
        next
        # end
      end
    rescue StandardError => e
      pending_induction_submission_batch.update(error_message: e.message)
    end

  private

    def debug(message)
      puts "====================================================="
      puts "#{message} - #{row['trn']} - #{row['objective']}"
      puts "====================================================="
    end

    def action_outcome!
      pending_induction_submission.assign_attributes(
        finished_on: row['end_date'],
        number_of_terms: row['number_of_terms'],
        outcome: row['objective']
      )

      if pending_induction_submission.save(context: :record_outcome)
        record_outcome.pass! if pending_induction_submission.pass?
        record_outcome.fail! if pending_induction_submission.fail?
      else
        pending_induction_submission.playback_errors
      end
    end

    def action_release!
      pending_induction_submission.assign_attributes(
        finished_on: row['end_date'],
        number_of_terms: row['number_of_terms'].to_f
      )

      if pending_induction_submission.save(context: :release_ect)
        release_ect.release!
      else
        pending_induction_submission.playback_errors
      end
    end

    def sparse_pending_induction_submission
      ::PendingInductionSubmission.create(
        pending_induction_submission_batch:,
        appropriate_body:,
        trn: row['trn'],
        date_of_birth: row['dob']
      )
    end

    # @return [nil, Teacher]
    def teacher
      ::Teacher.find_by(trn: pending_induction_submission.trn)
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

    def release_ect
      ReleaseECT.new(
        appropriate_body:,
        pending_induction_submission:,
        author:
      )
    end

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
