class ImportJob < ApplicationJob
  retry_on StandardError, attempts: 3

  def perform(pending_induction_submission_batch)
    # change state to PROCESSING
    pending_induction_submission_batch.processing!

    pending_induction_submission_batch.data.each do |row|
      pending_induction_submission =
        PendingInductionSubmission.new(
          pending_induction_submission_batch:,
          appropriate_body: pending_induction_submission_batch.appropriate_body,
          trn: row['trn'],
          trs_first_name: row['first_name'],
          trs_last_name: row['last_name'],
          date_of_birth: row['dob']
          # finished_on: nil,       # end_date
          # number_of_terms: nil,   # number_of_terms
          # outcome: nil            # objective
        )

      pending_induction_submission.save!

      find_ect =
        AppropriateBodies::ClaimAnECT::FindECT.new(
          appropriate_body: pending_induction_submission_batch.appropriate_body,
          pending_induction_submission:
        )

      find_ect.import_from_trs!
    rescue StandardError => e
      pending_induction_submission.update!(error_message: e.message)
      next
    end

    # change state to COMPLETED
    pending_induction_submission_batch.completed!
  rescue StandardError => e
    # capture batch error
    pending_induction_submission_batch.update!(error_message: e.message)

    # change state to FAILED
    pending_induction_submission_batch.failed!

    # retry
    raise
  end
end
