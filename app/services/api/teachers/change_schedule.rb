module API::Teachers
  class ChangeSchedule
    include API::Concerns::Teachers::SharedAction

    attribute :contract_period_year
    attribute :schedule_identifier

    validates :schedule_identifier, presence: { message: "The property '#/schedule_identifier' must be present and correspond to a valid schedule." }

    validate :schedule_exists
    validate :training_period_not_withdrawn
    validate :change_to_different_schedule
    validate :schedule_applicable_for_trainee
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
      @contract_period ||= ContractPeriod.find_by(year: contract_period_year) || fallback_contract_period
    end

    def fallback_contract_period
      training_period.contract_period
    end

    def schedule
      @schedule ||= Schedule.find_by(contract_period_year:, identifier: schedule_identifier) if contract_period && schedule_identifier
    end

    def schedule_exists
      return if errors[:schedule_identifier].any?
      return if schedule

      errors.add(:schedule_identifier, "The property '#/schedule_identifier' must be present and correspond to a valid schedule.")
    end

    def training_period_not_withdrawn
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?

      errors.add(:teacher_api_id, "Cannot perform actions on a withdrawn participant")
    end

    def change_to_different_schedule
      return if errors[:schedule_identifier].any?
      return unless training_period
      return if schedule != training_period.schedule

      errors.add(:schedule_identifier, "Selected schedule is already on the profile")
    end

    def schedule_applicable_for_trainee
      return if errors[:schedule_identifier].any?
      return unless training_period&.for_ect?

      errors.add(:schedule_identifier, "Selected schedule is not valid for the teacher_type") if schedule.replacement_schedule?
    end

    def school_partnership_exists_if_changing_contract_period
      return if errors[:contract_period_year].any?
      return unless training_period
      return if contract_period == training_period.contract_period
      return if school_partnership

      errors.add(:contract_period_year, "You cannot change a participant to this contract_period as you do not have a partnership with the school for the contract_period. Contact the DfE for assistance.")
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
