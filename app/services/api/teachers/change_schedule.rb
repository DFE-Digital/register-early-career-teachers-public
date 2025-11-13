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
    validate :no_future_training_periods_exist

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

      errors.add(:teacher_api_id, "You cannot change this participant's schedule. Only the lead provider currently training this participant can update their schedule.") unless training_period.ongoing_today?
    end

    def no_future_training_periods_exist
      return if errors[:teacher_api_id].any?
      return unless training_period

      if future_training_periods.exists?
        errors.add(:teacher_api_id, "You cannot change this participant’s schedule as they are due to start with another lead provider in the future.")
      end
    end

    def future_training_periods
      if training_period.for_mentor?
        TrainingPeriod
          .where.not(mentor_at_school_period_id: nil)
          .started_after(training_period.started_on)
      else
        TrainingPeriod
          .where.not(ect_at_school_period_id: nil)
          .started_after(training_period.started_on)
      end
    end
  end
end
