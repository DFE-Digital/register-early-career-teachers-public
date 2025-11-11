module API::Teachers
  class ChangeSchedule
    include API::Concerns::Teachers::SharedAction

    attribute :contract_period_year
    attribute :schedule_identifier

    validates :contract_period_year, presence: { message: "Enter a '#/contract_period_year'." }
    validates :schedule_identifier, presence: { message: "The property '#/schedule_identifier' must be present and correspond to a valid schedule." }

    validate :contract_period_exists
    validate :schedule_exists
    validate :training_period_not_already_withdrawn
    validate :change_to_different_schedule
    validate :valid_schedule_for_teacher_type
    validate :school_partnership_exists_if_changing_contract_period
    validate :lead_provider_is_currently_training_teacher

    def change_schedule
      return false unless valid?

      Teachers::ChangeSchedule.new(
        lead_provider:,
        teacher:,
        training_period:,
        schedule:,
        school_partnership:
      ).change_schedule
    end

  private

    def contract_period
      @contract_period ||= contract_period_year.present? ? ContractPeriod.find_by(year: contract_period_year) : fallback_contract_period
    end

    def fallback_contract_period
      training_period.contract_period
    end

    def schedule
      @schedule ||= Schedule.find_by(contract_period_year:, identifier: schedule_identifier) if contract_period && schedule_identifier
    end

    def contract_period_exists
      return if errors[:contract_period_year].any?
      return if contract_period

      errors.add(:contract_period_year, "The '#/contract_period_year' you have entered is invalid. Check contract period details and try again.")
    end

    def schedule_exists
      return if errors[:schedule_identifier].any?
      return if schedule

      errors.add(:schedule_identifier, "The property '#/schedule_identifier' must be present and correspond to a valid schedule")
    end

    def training_period_not_already_withdrawn
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?

      errors.add(:teacher_api_id, "Cannot perform actions on a withdrawn participant")
    end

    def change_to_different_schedule
      return if errors[:schedule_identifier].any?
      return unless training_period
      return if schedule != training_period.schedule

      errors.add(:schedule_identifier, "The '#/schedule_identifier' is already on the profile")
    end

    def valid_schedule_for_teacher_type
      return if errors[:schedule_identifier].any?
      return if schedule&.teacher_type == training_period&.schedule&.teacher_type

      errors.add(:schedule_identifier, "The '#/schedule_identifier' is not valid for '#/teacher_type'")
    end

    def school_partnership_exists_if_changing_contract_period
      return if errors[:contract_period_year].any?
      return unless training_period
      return if contract_period == training_period.contract_period
      return if school_partnership

      errors.add(:contract_period_year, "You cannot change a participant to this '#/contract_period_year' as you do not have a partnership with the school for the cohort. Contact the DfE for assistance.")
    end

    def school_partnership
      @school_partnership ||= SchoolPartnership
        .includes(:lead_provider, :contract_period)
        .joins(:lead_provider, :contract_period)
        .find_by(
          school: training_period.school_partnership.school,
          lead_providers: { id: training_period.lead_provider.id },
          contract_periods: { year: contract_period.id }
        )
    end

    def lead_provider_is_currently_training_teacher
      return if errors[:teacher_api_id].any?
      return unless training_period

      ongoing_school_period =
        if training_period.for_ect?
          teacher.ect_at_school_periods.ongoing_today.first
        elsif training_period.for_mentor?
          teacher.mentor_at_school_periods.ongoing_today.first
        end

      latest_training_period = ongoing_school_period&.training_periods&.latest_first&.first

      return if latest_training_period&.lead_provider == lead_provider

      errors.add(:teacher_api_id, "Lead provider is not currently training '#/teacher_api_id'.")
    end
  end
end
