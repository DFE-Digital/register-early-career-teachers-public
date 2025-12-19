module Declarations
  class Create
    attr_reader :author,
                :lead_provider,
                :teacher,
                :training_period,
                :declaration_date,
                :declaration_type,
                :evidence_type,
                :payment_statement,
                :mentorship_period,
                :delivery_partner

    def initialize(
      author:,
      lead_provider:,
      teacher:,
      training_period:,
      declaration_date:,
      declaration_type:,
      evidence_type:,
      payment_statement:,
      mentorship_period:,
      delivery_partner:
    )
      @author = author
      @lead_provider = lead_provider
      @teacher = teacher
      @training_period = training_period
      @declaration_date = declaration_date
      @declaration_type = declaration_type
      @evidence_type = evidence_type
      @payment_statement = payment_statement
      @mentorship_period = mentorship_period
      @delivery_partner = delivery_partner
    end

    def create
      ActiveRecord::Base.transaction do
        declaration = build_declaration

        set_eligibility_and_save!(declaration)
        update_uplifts!(declaration)
        set_payment_statement!(declaration)
        check_mentor_completion!(declaration)
        record_declaration_created_event!(declaration)

        declaration
      end
    end

  private

    def build_declaration
      training_period.declarations.build(
        declaration_date:,
        declaration_type:,
        evidence_type:,
        mentorship_period:
      )
    end

    def set_eligibility_and_save!(declaration)
      if declaration.duplicate_declaration_exists?
        declaration.mark_as_ineligible!(
          ineligibility_reason: :duplicate,
          payment_statement:,
          superseded_by: declaration.duplicate_declarations.order(created_at: :asc).first
        )
      elsif training_period.eligible_for_funding?
        declaration.mark_as_eligible!(payment_statement:)
      end
    ensure
      declaration.save!
    end

    def update_uplifts!(declaration)
      return unless declaration.for_ect?

      declaration.update!(
        pupil_premium_uplift: teacher.ect_pupil_premium_uplift,
        sparsity_uplift: teacher.ect_sparsity_uplift
      )
    end

    def set_payment_statement!(declaration)
      return if declaration.payment_status_no_payment?

      declaration.update!(payment_statement:)
    end

    def check_mentor_completion!(declaration)
      Declarations::MentorCompletion.new(author:, declaration:).perform
    end

    def record_declaration_created_event!(declaration)
      Events::Record.record_declaration_created_event!(
        author:,
        teacher:,
        lead_provider:,
        declaration:
      )
    end
  end
end
