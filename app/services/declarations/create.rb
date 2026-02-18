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
      # LPs making multiple same POST /declarations requests in a very quick succession may sometimes bypass the model validations
      # So we wrap creation in an advisory lock to dedupe concurrent requests for the same training period and declaration type
      # And return the existing declaration if found
      Declaration.with_advisory_lock("lock_#{training_period.id}_#{declaration_type}") do
        return existing_declaration if existing_declaration.present?

        ActiveRecord::Base.transaction do
          declaration = create_declaration

          update_uplifts!(declaration)
          set_eligibility!(declaration)
          set_payment_statement!(declaration)
          check_mentor_completion!(declaration)
          record_declaration_created_event!(declaration)

          declaration
        end
      end
    end

  private

    def existing_declaration
      @existing_declaration ||= Declaration
                                  .billable_or_changeable
                                  .find_by(
                                    training_period:,
                                    declaration_type:
                                  )
    end

    def create_declaration
      training_period.declarations.create!(
        declaration_date:,
        declaration_type:,
        evidence_type:,
        mentorship_period:,
        delivery_partner_when_created: training_period.delivery_partner
      )
    end

    def update_uplifts!(declaration)
      return unless declaration.declaration_type_started?
      return unless training_period.contract_period.uplift_fees_enabled?

      declaration.update!(
        pupil_premium_uplift: teacher.ect_pupil_premium_uplift,
        sparsity_uplift: teacher.ect_sparsity_uplift
      )
    end

    def set_eligibility!(declaration)
      if training_period.eligible_for_funding?
        declaration.update!(payment_status: :eligible, payment_statement:)
      end
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
