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

    validate :teacher_api_id_exists_and_is_registered_with_lead_provider
    validate :evidenced_at_is_in_the_past_and_within_milestone_and_in_sequence
    validate :teacher_type_exists_with_training
    validate :contract_period_is_not_payments_frozen_and_payment_statement_available
    validate :declaration_type_is_valid_and_correct_for_teacher_type

    validates :evidence_type, evidence_type: true, if: -> { errors.empty? }

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
      teacher_type == :ect ? teacher.ect_training_periods : teacher.mentor_training_periods
    end

    def training_period
      return unless teacher

      @training_period ||= training_periods
                             .includes(:lead_provider)
                             .where(framework_agreements: { lead_provider_id: })
                             .latest_first
                             .first
    end

    def milestone
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

    #########################################################
    ### teacher_api_id validations

    def teacher_api_id_exists_and_is_registered_with_lead_provider
      return if errors.any?

      teacher_api_id_is_not_blank
      teacher_api_id_is_registered_with_a_lead_provider
      teacher_api_id_has_not_withdrawn_before_evidenced_at
    end

    def teacher_api_id_is_not_blank
      return if errors.any?

      errors.add(:teacher_api_id, "Enter a '#/teacher_api_id'.") if teacher_api_id.blank?
    end

    def teacher_api_id_is_registered_with_a_lead_provider
      return if errors.any?
      return if teacher_registered_with_lead_provider?

      errors.add(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.")
    end

    def teacher_api_id_has_not_withdrawn_before_evidenced_at
      return if errors.any?
      return unless training_status&.withdrawn?
      return unless API::DateTimeFormatCheck.new(evidenced_at).valid?
      return unless training_period.withdrawn_at <= evidenced_at

      errors.add(:teacher_api_id, "This participant withdrew from this course on #{training_period.withdrawn_at.utc.rfc3339}. Enter a '#/evidenced_at' that's on or before the withdrawal date.")
    end

    #########################################################
    ### teacher_type validations

    def teacher_type_exists_with_training
      return if errors.any?

      teacher_type_is_not_blank
      teacher_type_is_a_valid_type_with_training
    end

    def teacher_type_is_not_blank
      return if errors.any?
      return if teacher_type.present?

      errors.add(:teacher_type, "Enter a '#/teacher_type'.")
    end

    def teacher_type_is_a_valid_type_with_training
      return if errors.any?

      if TEACHER_TYPES.exclude?(teacher_type) || (training_period.blank? && teacher_registered_with_lead_provider?)
        errors.add(:teacher_type,
                   "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again.")
      end
    end

    def teacher_registered_with_lead_provider?
      return false unless teacher

      [teacher.ect_training_periods, teacher.mentor_training_periods].any? do |periods|
        periods.includes(:lead_provider).where(framework_agreements: { lead_provider_id: }).exists?
      end
    end

    #########################################################
    ### evidenced_at validations

    def evidenced_at_is_in_the_past_and_within_milestone_and_in_sequence
      return if errors.any?

      evidenced_at_is_not_blank
      evidenced_at_is_in_rfc3339_format
      evidenced_at_is_in_the_past
      evidenced_at_is_within_milestone
      evidenced_at_is_in_sequence_with_existing_declaration_dates
    end

    def evidenced_at_is_not_blank
      return if errors.any?
      return if evidenced_at.present?

      errors.add(:evidenced_at, "Enter a '#/evidenced_at'.")
    end

    def evidenced_at_is_in_rfc3339_format
      return if errors.any?
      return if API::DateTimeFormatCheck.new(evidenced_at).valid?

      errors.add(:evidenced_at, "Enter a valid RFC3339 '#/evidenced_at'.")
    end

    def evidenced_at_is_in_the_past
      return if errors.any?
      return if parsed_evidenced_at.past?

      errors.add(:evidenced_at, "The '#/evidenced_at' value cannot be a future date. Check the date and try again.")
    end

    def evidenced_at_is_within_milestone
      return if errors.any?

      EvidencedAtWithinMilestoneValidator.new.validate(self)
    end

    def evidenced_at_is_in_sequence_with_existing_declaration_dates
      return if errors.any?
      return if declaration_type.blank?
      return unless contract_period && contract_period.year >= 2025

      ordered_types = Declaration.declaration_types.values
      index = ordered_types.index(declaration_type)
      before_declaration_types = ordered_types[0...index]
      after_declaration_types = ordered_types[(index + 1)..]

      from_evidenced_at = existing_declarations
        .billable_or_changeable_for_declaration_type(before_declaration_types)
        .maximum(:evidenced_at)

      to_evidenced_at = existing_declarations
        .billable_or_changeable_for_declaration_type(after_declaration_types)
        .minimum(:evidenced_at)

      error_message = "This '#/evidenced_at' is invalid. Check that it is in sequence with existing declaration dates for this participant."

      if from_evidenced_at && parsed_evidenced_at.before?(from_evidenced_at)
        errors.add(:evidenced_at, error_message)
      elsif to_evidenced_at && parsed_evidenced_at.after?(to_evidenced_at)
        errors.add(:evidenced_at, error_message)
      end
    end

    #########################################################
    ### declaration_type validations

    def declaration_type_is_valid_and_correct_for_teacher_type
      return if errors.any?

      declaration_type_is_not_blank
      declaration_type_is_a_valid_type

      return unless training_period

      declaration_type_does_not_already_exist
      declaration_type_is_correct_for_funded_mentor_training if training_period.for_mentor?
      declaration_type_has_a_schedule_milestone
    end

    def declaration_type_is_not_blank
      return if errors.any?
      return if declaration_type.present?

      errors.add(:declaration_type, "Enter a '#/declaration_type'.")
    end

    def declaration_type_is_a_valid_type
      return if errors.any?
      return if Declaration.declaration_types.key?(declaration_type)

      errors.add(:declaration_type, "Enter a valid declaration type.")
    end

    def declaration_type_does_not_already_exist
      return if errors.any?

      if existing_declarations.billable_or_changeable_for_declaration_type(declaration_type).exists?
        errors.add(:declaration_type, "A declaration has already been submitted that will be, or has been, paid for this event.")
      end
    end

    def declaration_type_is_correct_for_funded_mentor_training
      return if errors.any?
      return if declaration_type.in?(%w[started completed])
      return unless training_period.for_mentor?
      return unless contract_period.mentor_funding_enabled?

      errors.add(:declaration_type, "You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.")
    end

    def declaration_type_has_a_schedule_milestone
      return if errors.any?
      return if milestone.present?

      errors.add(:declaration_type, "The property '#/declaration_type' does not exist for this schedule.")
    end

    #########################################################
    ### contract_period validations

    def contract_period_is_not_payments_frozen_and_payment_statement_available
      return if errors.any?

      contract_period_is_not_payments_frozen
      contract_period_has_a_payment_statement_available
    end

    def contract_period_is_not_payments_frozen
      return if errors.any?

      training_period_ongoing_today = training_periods.contains_today.first
      return unless training_period_ongoing_today

      current_contract_period = training_period_ongoing_today.contract_period

      if current_contract_period&.payments_frozen?
        errors.add(:contract_period_year, "You cannot submit declarations for the #{current_contract_period.year} contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us.")
      end
    end

    def contract_period_has_a_payment_statement_available
      return if errors.any?

      if training_period&.eligible_for_funding? && payment_statement.blank?
        errors.add(:contract_period_year, "You cannot submit or void declarations for the #{contract_period.year} contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us.")
      end
    end

    def parsed_evidenced_at = Time.zone.parse(evidenced_at)
  end
end
