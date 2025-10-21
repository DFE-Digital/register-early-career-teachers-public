module Admin
  class RecordPass < ::AppropriateBodies::RecordPass
    attr_reader :note,
                :zendesk_ticket_id

    def initialize(note:, zendesk_ticket_id:, **args)
      @note = note
      @zendesk_ticket_id = zendesk_ticket_id
      super(**args)
    end

  private

    def record_pass_induction_event!
      Events::Record.record_teacher_passes_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:,
        body: note,
        zendesk_ticket_id:
      )
    end
  end
end
