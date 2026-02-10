module AppropriateBodies
  class RecordFail < CloseInduction
    validates :fail_confirmation_sent_on,
              presence: {
                message: "Enter the date you sent them written confirmation of their failed induction"
              },
              if: -> { author.appropriate_body_user? }

    # Only Appropriate Body users are required to provide a confirmation date
    def self.induction_params
      { model_name.param_key => %i[finished_on number_of_terms fail_confirmation_sent_on] }
    end

    def outcome = :fail

    def call(*)
      super

      validate_submission(context: :record_outcome)

      InductionPeriod.transaction do
        destroy_unstarted_ect_period!
        close_induction_period
        finish_ect_period_today
        delete_submission
        sync_with_trs
        update_event_history
      end
    end

  private

    def close_induction_period
      if author.appropriate_body_user?
        ongoing_induction_period.update!(number_of_terms:, finished_on:, outcome:, fail_confirmation_sent_on:)
      else
        super
      end
    end

    def update_event_history
      Events::Record.record_teacher_fails_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period,
        ect_at_school_period:,
        mentorship_period:,
        training_period:,
        body: "ECT notified on #{ongoing_induction_period.fail_confirmation_sent_on.to_fs(:govuk)}"
      )
    end

    def sync_with_trs
      FailECTInductionJob.perform_later(
        trn:,
        start_date: first_induction_period.started_on,
        completed_date: last_induction_period.finished_on
      )
    end
  end
end
