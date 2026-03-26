module API::Teachers
  class ChangeSchedule
    include API::Concerns::Teachers::SharedAction

    SCHEDULE_CHANGE_NOT_ALLOWED = "You cannot change this participant's schedule. Only the lead provider currently training this participant can update their schedule."

    attribute :contract_period_year
    attribute :schedule_identifier

    validates :schedule_identifier, presence: { message: "The property '#/schedule_identifier' must be present and correspond to a valid schedule." }

    validate :schedule_exists
    validate :training_period_not_withdrawn
    validate :change_to_different_schedule
    validate :schedule_applicable_for_trainee
    validate :school_partnership_exists_if_changing_contract_period
    validate :trainee_not_completed
    validate :training_period_not_finished
    validate :future_training_period_not_blocked_by_another_lead_provider
    validate :no_future_training_periods_with_different_lead_provider
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

    # The training period with the latest started_on for this LP, from metadata.
    def latest_training_period_from_metadata
      return unless metadata

      @latest_training_period_from_metadata ||=
        case teacher_type
        when :ect
          metadata.latest_ect_training_period
        when :mentor
          metadata.latest_mentor_training_period
        end
    end

    # The currently active training period for this LP.
    def ongoing_training_period
      return unless lead_provider

      ongoing_training_period_for_lead_provider
    end

    # The metadata training period, only if it hasn't started yet.
    def future_training_period
      tp = latest_training_period_from_metadata
      tp if tp&.started_on&.future?
    end

    # Overrides SharedAction#training_period. Metadata selects by latest started_on,
    # which picks a future TP over an ongoing one. We prefer ongoing so the schedule
    # change operates against the currently active record.
    def training_period
      return latest_training_period_from_metadata unless future_training_period

      ongoing_training_period || future_training_period
    end

  private

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

    # Prevents schedule changes on training periods that have finished.
    def training_period_not_finished
      return if errors[:teacher_api_id].any?
      return unless training_period
      return if future_training_period
      return if ongoing_training_period

      errors.add(:teacher_api_id, SCHEDULE_CHANGE_NOT_ALLOWED)
    end

    # Prevents schedule changes on future training periods when another LP is actively training the participant.
    # When no other LP is involved (e.g. a new ECT with a single future TP), the change is allowed.
    def future_training_period_not_blocked_by_another_lead_provider
      return if errors[:teacher_api_id].any?
      return unless future_training_period
      return unless ongoing_training_period_with_different_lead_provider?

      errors.add(:teacher_api_id, SCHEDULE_CHANGE_NOT_ALLOWED)
    end

    def ongoing_training_period_with_different_lead_provider?
      with_lead_provider_join(training_periods_for_teacher)
        .where.not(lead_providers: { id: lead_provider.id })
        .ongoing_today
        .exists?
    end

    def no_future_training_periods_with_different_lead_provider
      return if errors[:teacher_api_id].any?
      return unless training_period
      return unless future_training_periods_with_different_lead_provider.exists?

      errors.add(:teacher_api_id, "You cannot change this participant's schedule as they are due to start with another lead provider in the future.")
    end

    def future_training_periods_with_different_lead_provider
      with_lead_provider_join(training_periods_for_teacher.started_after(training_period.started_on))
        .where.not(lead_providers: { id: lead_provider.id })
    end

    # Base scope for all training periods belonging to this teacher, filtered by teacher type.
    def training_periods_for_teacher
      if teacher_type == :ect
        TrainingPeriod.joins(:ect_at_school_period).where(ect_at_school_period: { teacher: })
      else
        TrainingPeriod.joins(:mentor_at_school_period).where(mentor_at_school_period: { teacher: })
      end
    end

    # Joins a training period scope through to lead_providers for filtering by LP.
    def with_lead_provider_join(scope)
      scope.joins(school_partnership: { lead_provider_delivery_partnership: { active_lead_provider: :lead_provider } })
    end

    def ongoing_training_period_for_lead_provider
      with_lead_provider_join(training_periods_for_teacher)
        .where(lead_providers: { id: lead_provider.id })
        .ongoing_today
        .latest_first
        .first
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

      errors.add(:teacher_api_id, "You cannot change this participant's schedule as they have completed their training or induction.")
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
