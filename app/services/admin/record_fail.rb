module Admin
  class RecordFail < ::AppropriateBodies::RecordFail
    include Auditable

    def self.induction_params
      { model_name.param_key => %i[finished_on number_of_terms] }
    end

  private

    def update_event_history
      Events::Record.record_teacher_fails_induction_event!(
        author:,
        teacher:,
        appropriate_body_period:,
        induction_period: ongoing_induction_period,
        ect_at_school_period:,
        mentorship_period:,
        training_period:,
        body: note,
        zendesk_ticket_id:
      )
    end
  end
end
