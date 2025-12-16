module Declarations
  class Create
    attr_reader :author, :lead_provider, :teacher, :training_period, :declaration_date, :declaration_type, :evidence_type, :payment_statement, :mentorship_period, :delivery_partner

    def initialize(author:, lead_provider:, teacher:, training_period:, declaration_date:, declaration_type:, evidence_type:, payment_statement:, mentorship_period:, delivery_partner:)
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
        set_eligibility!
        set_payment_statement!
        check_mentor_completion!
        record_declaration_created_event!
      end

      declaration
    end

  private

    def existing_declarations
      @existing_declarations ||= if training_period.for_ect?
                                   teacher.ect_declarations
                                 else
                                   teacher.mentor_declarations
                                 end
    end

    def existing_declaration
      @existing_declaration ||= existing_declarations
        .billable_or_changeable
        .joins(:lead_provider, :delivery_partner)
        .find_by(
          declaration_date:,
          declaration_type:,
          evidence_type:,
          mentorship_period:,
          lead_provider: { id: lead_provider.id },
          delivery_partner: { id: delivery_partner.id }
        )
    end

    def find_or_create_declaration
      existing_declaration || training_period.declarations.create!(
        declaration_date:,
        declaration_type:,
        evidence_type:,
        mentorship_period:
      )
    end

    def declaration
      @declaration ||= find_or_create_declaration.tap do |d|
        d.update!(
          {
            pupil_premium_uplift: teacher.ect_pupil_premium_uplift,
            sparsity_uplift: teacher.ect_sparsity_uplift
          }
        )
      end
    end

    def set_eligibility!
      if training_period.eligible_for_funding?
        declaration.update!(payment_status: :eligible, payment_statement:)
      end
    end

    def set_payment_statement!
      return if declaration.payment_status_no_payment?

      declaration.update!(payment_statement:)
    end

    def check_mentor_completion!
      Declarations::MentorCompletion.new(author:, declaration:).perform
    end

    def record_declaration_created_event!
      Events::Record.record_declaration_created_event!(
        author:,
        teacher:,
        lead_provider:,
        declaration:
      )
    end
  end
end
