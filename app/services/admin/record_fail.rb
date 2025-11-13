module Admin
  class RecordFail < ::AppropriateBodies::RecordFail
    include Auditable

  private

    def update_event_history
      Events::Record.record_teacher_fails_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period,
        body: note,
        zendesk_ticket_id:
      )
    end
  end
end
