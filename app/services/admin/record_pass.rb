module Admin
  class RecordPass < ::AppropriateBodies::RecordPass
    include Auditable

    def pass!
      validate!

      fail unless valid?

      super
    end

  private

    def record_pass_induction_event!
      Events::Record.record_teacher_passes_induction_event!(
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
