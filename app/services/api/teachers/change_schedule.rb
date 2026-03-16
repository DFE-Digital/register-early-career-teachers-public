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
    validate :trainee_not_completed
    validate :lead_provider_is_currently_training_teacher
    validate :no_future_training_periods_exist
    validate :can_move_to_frozen_contract_period
    validate :schedule_does_not_invalidate_declarations

    def change_schedule
      return false unless valid?

      Teachers::ChangeSchedule.new(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        lead_provider:,
        teacher:,
        training_period:,
        schedule:,
        school_partnership:
      ).change_schedule
    end

    # The metadata handler selects the training period with the latest started_on.
    # When a future training period exists for the same lead provider, it gets selected
    # instead of the ongoing one, causing lead_provider_is_currently_training_teacher
    # to reject it (started_on.future?). We fall back to the ongoing training period
    # so the schedule change can proceed against the correct record.
    def training_period
      tp = super
      return tp unless tp&.started_on&.future?

      ongoing_training_period_for_lead_provider || tp
    end

  private

    def ongoing_training_period_for_lead_provider
      scope = if teacher_type == :ect
                TrainingPeriod.joins(:ect_at_school_period).where(ect_at_school_period: { teacher: })
              else
                TrainingPeriod.joins(:mentor_at_school_period).where(mentor_at_school_period: { teacher: })
              end

      scope
        .joins(school_partnership: { lead_provider_delivery_partnership: { active_lead_provider: :lead_provider } })
        .where(lead_providers: { id: lead_provider.id })
        .ongoing_today
        .latest_first
        .first
    end

    def contract_period
      @contract_period ||= ContractPeriod.find_by(year: contract_period_year) || fallback_contract_period
    end

    def fallback_contract_period
      training_period&.contract_period
    end

    def schedule
      @schedule ||= Schedule.find_by(contract_period_year: contract_period.year, identifier: schedule_identifier) if contract_period && schedule_identifier
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

      unless !training_period.started_on.future? && training_period.ongoing_today?
        errors.add(:teacher_api_id, "You cannot change this participant's schedule. Only the lead provider currently training this participant can update their schedule.")
      end
    end

    def no_future_training_periods_exist
      return if errors[:teacher_api_id].any?
      return unless training_period

      if future_training_periods_with_different_lead_provider.exists?
        errors.add(:teacher_api_id, "You cannot change this participant’s schedule as they are due to start with another lead provider in the future.")
      end
    end

    def future_training_periods
      if training_period.for_mentor?
        TrainingPeriod
          .joins(:mentor_at_school_period)
          .where(mentor_at_school_period: { teacher: })
          .started_after(training_period.started_on)
      else
        TrainingPeriod
          .joins(:ect_at_school_period)
          .where(ect_at_school_period: { teacher: })
          .started_after(training_period.started_on)
      end
    end

    def future_training_periods_with_different_lead_provider
      future_training_periods
        .joins(school_partnership: { lead_provider_delivery_partnership: { active_lead_provider: :lead_provider } })
        .where.not(lead_providers: { id: lead_provider.id })
    end

    def can_move_to_frozen_contract_period
      return unless contract_period&.payments_frozen?

      original_frozen_year = training_period.for_ect? ? teacher.ect_payments_frozen_year : teacher.mentor_payments_frozen_year

      unless original_frozen_year == contract_period.year
        errors.add(:contract_period_year, "You cannot move a participant to a payments frozen contract period unless they previously belonged to that contract period.")
      end
    end

    def trainee_not_completed
      return if errors[:teacher_api_id].any?
      return unless training_period&.teacher_completed_training?

      errors.add(:teacher_api_id, "You cannot change this participant’s schedule as they have completed their training or induction.")
    end

    def schedule_does_not_invalidate_declarations
      return if errors[:schedule_identifier].any?
      return unless training_period
      return if training_period.started_on.past?
      return unless declarations_would_become_invalid?

      errors.add(:schedule_identifier, "The change of schedule cannot be applied because a previous change of schedule and a declaration were made on the same day. Applying another change of schedule would invalidate existing declarations. Please contact DfE for assistance.")
    end

    def declarations_would_become_invalid?
      original = training_period.schedule
      training_period.schedule = schedule

      training_period.declarations.any?(&:invalid?)
    ensure
      training_period.schedule = original
    end
  end
end
