module Admin
  class RecordFail < ::AppropriateBodies::RecordFail
    include Auditable

    def fail!
      validate!

      fail unless valid?

      super
    end

  private

    def record_fail_induction_event!
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
