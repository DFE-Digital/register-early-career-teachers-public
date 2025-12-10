module Declarations
  class Create
    attr_reader :author, :lead_provider, :teacher, :training_period, :declaration_date, :declaration_type, :evidence_type

    def initialize(author:, lead_provider:, teacher:, training_period:, declaration_date:, declaration_type:, evidence_type:)
      @author = author
      @lead_provider = lead_provider
      @teacher = teacher
      @training_period = training_period
      @declaration_date = declaration_date
      @declaration_type = declaration_type
      @evidence_type = evidence_type
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

    def mentorship_period
      return unless training_period.for_ect?

      @mentorship_period ||= training_period.trainee.mentorship_periods.ongoing_or_closest_to(declaration_date).earliest_first.first
    end

    def existing_declaration
      @existing_declaration ||= training_period
        .declarations
        .no_payment_or_billable
        .find_by(
          declaration_type:,
          declaration_date:,
          evidence_type:,
          mentorship_period:
        )
    end

    def find_declaration
      existing_declaration || training_period.declarations.create!(
        declaration_date:,
        declaration_type:,
        evidence_type: declaration_type != "started" ? evidence_type : nil,
        mentorship_period:
      )
    end

    def declaration
      @declaration ||= find_declaration.tap do |pd|
        pd.update!(
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

    def payment_statement
      @payment_statement ||= Statements::Search.new(lead_provider_id: lead_provider.id,
                                                    contract_period_years: training_period.contract_period.year,
                                                    fee_type: "output",
                                                    deadline_date: Time.zone.today..,
                                                    order: :deadline_date).statements.first
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
