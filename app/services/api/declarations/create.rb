module API::Declarations
  class Create
    include API::Concerns::Declarations::SharedAction

    TEACHER_TYPES = %i[ect mentor].freeze

    attribute :teacher_api_id
    attribute :teacher_type
    attribute :declaration_date
    attribute :declaration_type
    attribute :evidence_type

    validates :teacher_api_id, presence: { message: "Enter a '#/teacher_api_id'." }
    validates :teacher_type, presence: { message: "Enter a '#/teacher_type'." }
    validate :teacher_training_exists
    validates :teacher_type, inclusion: {
      in: TEACHER_TYPES,
      message: "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again."
    }, allow_blank: true
    validates :declaration_date, presence: { message: "Enter a '#/declaration_date'." }
    validate :declaration_date_in_the_past
    validates :declaration_date,
              declaration_date_within_milestone: true,
              api_date_time_format: true,
              allow_blank: true
    validates :declaration_type, presence: { message: "Enter a '#/declaration_type'." }
    validates :evidence_type, evidence_type: true
    validate :validate_only_started_or_completed_if_mentor
    validate :teacher_not_withdrawn_before_declaration_date
    validate :validate_milestone_exists
    validate :validates_billable_slot_available
    validate :payment_statement_available

    def create
      return false unless valid?

      Declarations::Create.new(
        author:,
        lead_provider:,
        teacher:,
        training_period:,
        declaration_date:,
        declaration_type:,
        evidence_type: EvidenceTypeValidator.evidence_type_allowed?(self) ? evidence_type : nil,
        payment_statement:,
        mentorship_period:,
        delivery_partner:
      ).create
    end

    def training_period
      return unless teacher

      @training_period ||= case teacher_type
                           when :ect
                             teacher.ect_training_periods
                             .includes(:lead_provider)
                             .where(active_lead_providers: { lead_provider_id: })
                             .closest_to(declaration_date)
                             .first
                           when :mentor
                             teacher.mentor_training_periods
                             .includes(:lead_provider)
                             .where(active_lead_providers: { lead_provider_id: })
                             .closest_to(declaration_date)
                             .first
                           end
    end

    def milestone
      @milestone ||= schedule&.milestones&.find_by(declaration_type:)
    end

  private

    def teacher
      @teacher ||= Teacher.find_by(api_id: teacher_api_id) if teacher_api_id
    end

    def schedule
      @schedule ||= training_period&.schedule
    end

    def contract_period
      @contract_period ||= schedule&.contract_period
    end

    def mentorship_period
      return unless training_period.for_ect?

      @mentorship_period ||= training_period.trainee.mentorship_periods.closest_to(declaration_date).first
    end

    def delivery_partner
      @delivery_partner ||= training_period.delivery_partner
    end

    def training_status
      @training_status ||= API::TrainingPeriods::TrainingStatus.new(training_period:) if training_period
    end

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

    def payment_statement
      @payment_statement ||= Statements::Search.new(
        lead_provider_id:,
        contract_period_years: contract_period.year,
        fee_type: "output",
        deadline_date: Time.zone.today..,
        order: :deadline_date
      ).statements.first
    end

    def declaration_date_in_the_past
      return if errors[:declaration_date].any?

      if declaration_date && declaration_date > Time.zone.now
        errors.add(:declaration_date, "The '#/declaration_date' value cannot be a future date. Check the date and try again.")
      end
    end

    def teacher_training_exists
      return if errors[:teacher_api_id].any?
      return if training_period

      errors.add(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.")
    end

    def validate_milestone_exists
      return if errors[:declaration_type].any?
      return if errors[:teacher_api_id].any?

      if milestone.blank?
        errors.add(:declaration_type, "The property '#/declaration_type' does not exist for this schedule.")
      end
    end

    def teacher_not_withdrawn_before_declaration_date
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
      return unless existing_declarations.billable_or_changeable_for_declaration_type(declaration_type).exists?

      errors.add(:base, "A declaration has already been submitted that will be, or has been, paid for this event.")
    end

    def payment_statement_available
      return unless training_period
      return if existing_declaration&.payment_status_no_payment?
      return if existing_declaration.nil? && !training_period.eligible_for_funding?
      return if payment_statement.present?

      errors.add(:contract_period_year, "You cannot submit or void declarations for the #{contract_period.year} contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us.")
    end
  end
end
