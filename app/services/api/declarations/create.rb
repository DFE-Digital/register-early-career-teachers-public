module API::Declarations
  class Create
    include API::Concerns::Teachers::SharedAction

    attribute :declaration_date
    attribute :declaration_type
    attribute :evidence_type

    validates :declaration_date, presence: { message: "Enter a '#/declaration_date'." }
    validates :declaration_date,
              future_date: true,
              declaration_date_within_milestone: true,
              declaration_date_format: true,
              allow_blank: true
    validates :declaration_type, presence: { message: "Enter a '#/declaration_type'." }
    validates :evidence_type, evidence_type: true
    validate :validate_only_started_or_completed_if_mentor
    validate :teacher_not_withdrawn
    validate :validate_milestone_exists
    validate :validates_billable_slot_available
    validate :payment_statement_available

    def create
      return false unless valid?

      Declarations::Create.new(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        lead_provider:,
        teacher:,
        training_period:,
        declaration_date:,
        declaration_type:,
        evidence_type:
      ).create
    end

    def training_period
      return unless teacher

      @training_period ||= case teacher_type
                           when :ect
                             teacher.ect_training_periods
                             .includes(:lead_provider)
                             .where(active_lead_providers: { lead_provider_id: })
                             .ongoing_or_closest_to(declaration_date)
                             .earliest_first
                             .first
                           when :mentor
                             teacher.mentor_training_periods
                             .includes(:lead_provider)
                             .where(active_lead_providers: { lead_provider_id: })
                             .ongoing_or_closest_to(declaration_date)
                             .earliest_first
                             .first
                           end
    end

    def milestone
      @milestone ||= schedule&.milestones&.find_by(declaration_type:)
    end

  private

    def schedule
      @schedule ||= training_period&.schedule
    end

    def contract_period
      @contract_period ||= schedule&.contract_period
    end

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

    def validate_milestone_exists
      return if errors[:declaration_type].any?
      return if errors[:teacher_api_id].any?

      if milestone.blank?
        errors.add(:declaration_type, "The property '#/declaration_type' does not exist for this schedule.")
      end
    end

    def teacher_not_withdrawn
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?
      return unless training_period.withdrawn_at <= declaration_date

      errors.add(:teacher_api_id, "This participant withdrew from this course on #{training_period.withdrawn_at.rfc3339}. Enter a '#/declaration_date' that's on or before the withdrawal date.")
    end

    def validate_only_started_or_completed_if_mentor
      return if errors[:declaration_type].any?
      return if declaration_type&.in?(%w[started completed])
      return unless training_period&.for_mentor?
      return unless contract_period.mentor_funding_enabled?

      errors.add(:declaration_type, "You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.")
    end

    def validates_billable_slot_available
      return unless training_period
      return unless training_period.declarations.no_payment_or_billable_for_declaration_type(declaration_type).exists?

      errors.add(:base, "A declaration has already been submitted that will be, or has been, paid for this event.")
    end

    def payment_statement
      @payment_statement ||= Statements::Search.new(
        lead_provider_id:,
        contract_period_years: contract_period.year,
        fee_type: "output",
        deadline_date: Time.zone.today..,
        order: :deadline_date
      ).statements.first
    end

    def payment_statement_available
      return unless training_period
      return if existing_declaration&.payment_status_no_payment?
      return if existing_declaration.nil? && !training_period.eligible_for_funding?
      return if payment_statement.present?

      errors.add(:contract_period_year, "You cannot submit or void declarations for the #{contract_period.year} cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us.")
    end
  end
end
