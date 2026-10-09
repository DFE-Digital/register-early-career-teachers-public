module API::Declarations
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindDeclaration
    include API::FindLeadProvider
    include API::LeadProviderAuthor

    TEACHER_TYPES = %i[ect mentor].freeze

    attribute :declaration_api_id
    attribute :lead_provider_id

    attribute :teacher_api_id
    attribute :teacher_type
    attribute :evidenced_at
    attribute :declaration_type
    attribute :evidence_type

    validate :teacher_exists_with_lead_provider

    validates :evidenced_at, presence: { message: "Enter a '#/evidenced_at'." },
                             api_date_time_format: true,
                             inclusion: { in: :evidenced_at_date_range,
                                          message: ->(object, _) { object.send(:evidenced_at_date_range_error_message) } },
                             if: -> { errors.empty? }

    validate :training_period_exists_for_teacher_type, if: -> { errors.empty? }

    validates :declaration_type, presence: { message: "Enter a '#/declaration_type'." }, if: -> { errors.empty? }
    validates :declaration_type, inclusion: {
      in: Declaration.declaration_types.keys,
      message: "Enter a valid declaration type."
    }, allow_blank: true, if: -> { errors.empty? }
    validate :validates_billable_slot_available
    validate :validate_only_started_or_completed_if_mentor
    validates :evidence_type, evidence_type: true, if: -> { errors.empty? }
    validate :teacher_not_withdrawn_before_evidenced_at
    validate :contract_period_is_not_payments_frozen
    validate :payment_statement_available
    validate :validate_milestone_exists

    def create
      return false unless valid?

      Declarations::Create.new(
        author:,
        lead_provider:,
        teacher:,
        training_period:,
        evidenced_at:,
        declaration_type:,
        evidence_type:,
        payment_statement:,
        mentorship_period:,
        delivery_partner:
      ).create
    end

    def training_periods
      @training_periods ||= if teacher_type == :ect
                              teacher&.ect_training_periods
                            elsif teacher_type == :mentor
                              teacher&.mentor_training_periods
                            end

      @training_periods || TrainingPeriod.none
    end

    def training_period
      @training_period ||= training_periods
                             .includes(:lead_provider)
                             .where(framework_agreements: { lead_provider_id: })
                             .latest_first
                             .first
    end

    def milestone
      return unless Milestone.declaration_types.key?(declaration_type)

      @milestone ||= schedule&.milestones&.find_by(declaration_type:)
    end

    def evidence_type
      @evidence_type ||= EvidenceTypeValidator.evidence_type_allowed?(self) ? super : nil
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

      @mentorship_period ||= training_period.mentorship_periods.closest_to(evidenced_at).first
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

    def payment_statement
      @payment_statement ||= Statements::Search.new(
        lead_provider_id:,
        contract_period_years: contract_period.year,
        fee_type: "output",
        status: "open",
        deadline_date: Time.zone.today..,
        order: :deadline_date
      ).statements.first
    end

    def teacher_exists_with_lead_provider
      return if errors.any?

      return errors.add(:teacher_api_id, "Enter a '#/teacher_api_id'.") if teacher_api_id.blank?
      return errors.add(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.") unless training_period_exists_for_lead_provider?

      return unless training_status&.withdrawn?
      return unless training_period.withdrawn_at <= evidenced_at

      errors.add(:teacher_api_id, "This participant withdrew from this course on #{training_period.withdrawn_at.utc.rfc3339}. Enter a '#/evidenced_at' that's on or before the withdrawal date.")
    end

    def training_period_exists_for_teacher_type
      return errors.add(:teacher_type, message: "Enter a '#/teacher_type'.") if teacher_type.blank?
      return if training_period

      errors.add(:teacher_type, "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again.")
    end

    def training_period_exists_for_lead_provider?
      return false unless teacher

      teacher
        .training_periods
        .includes(:lead_provider)
        .where(framework_agreements: { lead_provider_id: })
        .exists?
    end

    def validate_milestone_exists
      return if errors[:evidenced_at].any?
      return if errors[:declaration_type].any?
      return if errors[:teacher_api_id].any?
      return if errors[:teacher_type].any?
      return if errors[:lead_provider_id].any?
      return if errors[:contract_period_year].any?
      return unless training_period

      if milestone.blank?
        errors.add(:declaration_type, "The property '#/declaration_type' does not exist for this schedule.")
      end
    end

    def teacher_not_withdrawn_before_evidenced_at
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?
      return unless training_period.withdrawn_at <= evidenced_at

      errors.add(:teacher_api_id, "This participant withdrew from this course on #{training_period.withdrawn_at.utc.rfc3339}. Enter a '#/evidenced_at' that's on or before the withdrawal date.")
    end

    def validate_only_started_or_completed_if_mentor
      return if errors[:declaration_type].any?
      return if errors[:contract_period_year].any?
      return if declaration_type&.in?(%w[started completed])
      return unless training_period&.for_mentor?
      return unless contract_period.mentor_funding_enabled?

      errors.add(:declaration_type, "You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.")
    end

    def validates_billable_slot_available
      return if errors[:declaration_type].any?
      return if errors[:evidenced_at].any?
      return unless training_period
      return unless existing_declarations.billable_or_changeable_for_declaration_type(declaration_type).exists?

      errors.add(:declaration_type, "A declaration has already been submitted that will be, or has been, paid for this event.")
    end

    def payment_statement_available
      return if errors[:declaration_type].any?
      return if errors[:contract_period_year].any?
      return unless training_period&.eligible_for_funding?
      return if payment_statement.present?

      errors.add(:contract_period_year, "You cannot submit or void declarations for the #{contract_period.year} contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us.")
    end

    def contract_period_is_not_payments_frozen
      return if errors[:contract_period_year].any?
      return unless teacher

      training_period_ongoing_today = training_periods.contains_today.first
      return unless training_period_ongoing_today

      current_contract_period = training_period_ongoing_today.contract_period
      return unless current_contract_period&.payments_frozen?

      errors.add(:contract_period_year, "You cannot submit declarations for the #{current_contract_period.year} contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us.")
    end

    def milestone_started_at
      @milestone_started_at ||= milestone.start_date.beginning_of_day
    end

    def milestone_finished_at
      @milestone_finished_at ||= milestone.milestone_date&.end_of_day
    end

    def evidenced_at_date_range
      return (..Time.zone.now) unless milestone

      range = if contract_period.year < 2025
                milestone_started_at..milestone_finished_at
              else
                surrounding_declaration_date_range
              end

      range.begin..[range.end, Time.zone.now].compact.min
    end

    def surrounding_declaration_date_range
      types = Declaration.declaration_types.values
      index = types.index(declaration_type)

      before = existing_declarations.billable_or_changeable_for_declaration_type(types.take(index))
      after = existing_declarations.billable_or_changeable_for_declaration_type(types.drop(index + 1))

      before.maximum(:evidenced_at)..after.minimum(:evidenced_at)
    end

    def evidenced_at_date_range_error_message
      if parsed_evidenced_at.future?
        "The '#/evidenced_at' value cannot be a future date. Check the date and try again."
      elsif evidenced_at < milestone_started_at
        "Evidenced at must be on or after the milestone start date for the same declaration type."
      elsif milestone_finished_at.present? && evidenced_at > milestone_finished_at
        "Evidenced at must be on or before the milestone date for the same declaration type."
      else
        "This '#/evidenced_at' is invalid. Check that it is in sequence with existing declaration dates for this participant."
      end
    end

    def parsed_evidenced_at = Time.zone.parse(evidenced_at)
  end
end
