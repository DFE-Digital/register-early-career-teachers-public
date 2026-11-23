module Backfill
  class RecordDeclarationVoidEvent
    attr_reader :declaration

    def initialize(declaration:)
      @declaration = declaration
    end

    def process
      return false if declaration.events.exists?(event_type:)

      Event.create!(
        event_type:,
        heading:,
        body:,
        happened_at: declaration.voided_by_user_at,
        declaration:,
        teacher:,
        training_period: declaration.training_period,
        author_id: voided_by_user.id,
        author_name: voided_by_user.name,
        author_email: voided_by_user.email,
        author_type: "dfe_staff_user"
      )

      true
    end

  private

    delegate :teacher, :voided_by_user, to: :declaration

    def event_type
      if declaration.payment_status_voided? && declaration.clawback_status_no_clawback?
        "teacher_declaration_voided"
      elsif declaration.payment_status_paid? && declaration.clawback_status.in?(Declaration::REFUNDABLE_CLAWBACK_STATUSES)
        "teacher_declaration_awaiting_clawback"
      else
        raise ArgumentError, "Declaration must be voided, awaiting clawback or clawed back"
      end
    end

    def heading
      teacher_name = Teachers::Name.new(teacher).full_name

      if declaration.payment_status_voided?
        "#{teacher_name}’s declaration was voided"
      else
        "#{teacher_name}’s declaration was marked as awaiting clawback"
      end
    end

    def body
      action = declaration.payment_status_voided? ? "voided" : "marked as awaiting clawback"

      "The declaration was #{action} on the date shown. " \
        "This timeline entry was added retrospectively using the details already recorded on the declaration."
    end
  end
end
