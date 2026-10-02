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

    validate :teacher_exists_and_is_registered_with_lead_provider
    validate :evidenced_at_is_in_the_past_and_within_milestone

    validate :teacher_type_exists_with_training

    # moved higher up - was after teacher_not_withdrawn_before_evidenced_at
    validate :contract_period_is_not_payments_frozen

    validate :declaration_type_is_valid_and_correct_for_teacher_type

    # validates :declaration_type, presence: { message: "Enter a '#/declaration_type'." }, if: -> { errors.empty? }
    # validates :declaration_type, inclusion: {
    #   in: Declaration.declaration_types.keys,
    #   message: "Enter a valid declaration type."
    # }, allow_blank: true, if: -> { errors.empty? }

    validate :validates_billable_slot_available
    # validate :validate_only_started_or_completed_if_mentor

    validates :evidence_type, evidence_type: true, if: -> { errors.empty? }

    validate :teacher_not_withdrawn_before_evidenced_at
    # validate :contract_period_is_not_payments_frozen
    validate :payment_statement_available
    # validate :validate_milestone_exists
    validate :declaration_in_sequence
    # validate :teacher_registered_with_lead_provider

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

    def teacher_exists_and_is_registered_with_lead_provider
      return if errors.any?

      errors.add(:teacher_api_id, "Enter a '#/teacher_api_id'.") and return if teacher_api_id.blank?

      return if teacher_registered_with_lead_provider?
      errors.add(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.")
    end

    def teacher_type_exists_with_training
      return if errors.any?

      errors.add(:teacher_type, "Enter a '#/teacher_type'.") and return if teacher_type.blank?

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

    def evidenced_at_is_in_the_past_and_within_milestone
      return if errors.any?

      if evidenced_at.blank?
        errors.add(:evidenced_at, "Enter a '#/evidenced_at'.")
      elsif API::DateTimeFormatCheck.new(evidenced_at).invalid?
        errors.add(:evidenced_at, "Enter a valid RFC3339 '#/evidenced_at'.")
      elsif evidenced_at > Time.zone.now
        errors.add(:evidenced_at, "The '#/evidenced_at' value cannot be a future date. Check the date and try again.")
      else
        EvidencedAtWithinMilestoneValidator.new.validate(self)
      end
    end

    def declaration_type_is_valid_and_correct_for_teacher_type
      return if errors.any?

      errors.add(:declaration_type, "Enter a '#/declaration_type'.") and return if declaration_type.blank?

      if Declaration.declaration_types.keys.exclude?(declaration_type)
        errors.add(:declaration_type, "Enter a valid declaration type.")
        return
      end

      unless declaration_type.in?(%w[started completed])
        if training_period&.for_mentor? && contract_period.mentor_funding_enabled?
          errors.add(:declaration_type, "You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.")
          return
        end
      end

      if training_period.present? && milestone.blank?
        errors.add(:declaration_type, "The property '#/declaration_type' does not exist for this schedule.")
      end
    end

    # def validate_milestone_exists
    #   return if errors[:evidenced_at].any?
    #   return if errors[:declaration_type].any?
    #   return if errors[:teacher_api_id].any?
    #   return if errors[:teacher_type].any?
    #   return if errors[:lead_provider_id].any?
    #   return if errors[:contract_period_year].any?
    #   return unless training_period

    #   if milestone.blank?
    #     errors.add(:declaration_type, "The property '#/declaration_type' does not exist for this schedule.")
    #   end
    # end

    def teacher_not_withdrawn_before_evidenced_at
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?
      return unless training_period.withdrawn_at <= evidenced_at

      errors.add(:teacher_api_id, "This participant withdrew from this course on #{training_period.withdrawn_at.utc.rfc3339}. Enter a '#/evidenced_at' that's on or before the withdrawal date.")
    end

    # def validate_only_started_or_completed_if_mentor
    #   return if errors[:declaration_type].any?
    #   return if errors[:contract_period_year].any?
    #   return if declaration_type&.in?(%w[started completed])
    #   return unless training_period&.for_mentor?
    #   return unless contract_period.mentor_funding_enabled?

    #   errors.add(:declaration_type, "You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.")
    # end

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

    def declaration_in_sequence
      return if errors[:evidenced_at].any? || errors[:declaration_type].any?
      return if evidenced_at.blank? || declaration_type.blank?
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

    def parsed_evidenced_at = Time.zone.parse(evidenced_at)
  end
end
