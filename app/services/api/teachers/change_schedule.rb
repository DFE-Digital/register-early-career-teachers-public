module API::Teachers
  class ChangeSchedule
    include API::Concerns::Teachers::SharedAction

    attribute :contract_period_year
    attribute :schedule_identifier

    validates :schedule_identifier, presence: { message: "The property '#/schedule_identifier' must be present and correspond to a valid schedule." }
    validates :schedule_identifier, inclusion: { in: Schedule.identifiers.keys, message: "Enter a valid schedule identifier." }, allow_blank: true
    validate :schedule_acceptable_for_change, if: -> { errors[:schedule_identifier].empty? }
    validate :contract_period_acceptable_for_change, if: -> { training_period && errors[:contract_period_year].empty? }
    validate :teacher_can_change_schedule, if: -> { training_period && errors[:teacher_api_id].empty? }

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

  private

    def schedule_acceptable_for_change
      return errors.add(:schedule_identifier, "The property '#/schedule_identifier' must be present and correspond to a valid schedule.") unless schedule
      return unless training_period
      return errors.add(:schedule_identifier, "Selected schedule is already on the profile") if schedule == training_period.schedule
      return errors.add(:schedule_identifier, "Selected schedule is not valid for the teacher_type") if training_period.for_ect? && schedule.replacement_schedule?
      return errors.add(:schedule_identifier, "Mentors cannot be placed on a reduced schedule. Assign them to a different schedule.") if training_period.for_mentor? && schedule.reduced_schedule?
      return if training_period.started_on.past?
      return unless declarations_would_become_invalid?

      errors.add(:schedule_identifier, "The change of schedule cannot be applied because a previous change of schedule and a declaration were made on the same day. Applying another change of schedule would invalidate existing declarations. Please contact DfE for assistance.")
    end

    def contract_period_acceptable_for_change
      return errors.add(:contract_period_year, "You cannot change a participant to this contract_period as you do not have a partnership with the school for the contract_period. Contact the DfE for assistance.") if contract_period_changing? && school_partnership.nil?
      return unless contract_period&.payments_frozen?

      original_frozen_year = training_period.for_ect? ? teacher.ect_payments_frozen_year : teacher.mentor_payments_frozen_year
      return if original_frozen_year == contract_period.year

      errors.add(:contract_period_year, "You cannot move a participant to a payments frozen contract period unless they previously belonged to that contract period.")
    end

    def teacher_can_change_schedule
      return errors.add(:teacher_api_id, "You cannot change this participant's schedule as they have completed their training or induction.") if training_period.teacher_completed_training? && !ect_moving_to_reduced_schedule?
      return errors.add(:teacher_api_id, "You cannot change this participant's schedule. This is because the participant has a 'left' participant_status, so they are not training with you currently.") if participant_status.left?
      return errors.add(:teacher_api_id, "Cannot perform actions on a withdrawn participant") if training_status.withdrawn?
      return unless future_training_periods.exists?

      errors.add(:teacher_api_id, "You cannot change this participant's schedule as they are due to start with another lead provider in the future.")
    end

    def contract_period
      @contract_period ||= ContractPeriod.find_by(year: contract_period_year) || training_period&.contract_period
    end

    def schedule
      return unless contract_period && schedule_identifier

      @schedule ||= contract_period.schedules.find_by(identifier: schedule_identifier)
    end

    def contract_period_changing?
      contract_period != training_period&.contract_period
    end

    def school_partnership
      @school_partnership ||= find_school_partnership
    end

    def find_school_partnership
      return unless existing_school_partnership && active_lead_provider
      return existing_school_partnership unless contract_period_changing?

      school_partnership_with_same_delivery_partner || available_school_partnerships.first
    end

    def existing_school_partnership
      @existing_school_partnership ||= training_period&.school_partnership
    end

    def school_partnership_with_same_delivery_partner
      available_school_partnerships
        .find_by(lead_provider_delivery_partnership: { delivery_partner: existing_school_partnership.delivery_partner })
    end

    def available_school_partnerships
      active_lead_provider
        .school_partnerships
        .joins(:delivery_partner)
        .where(school: existing_school_partnership.school)
        .order(created_at: :desc)
    end

    def active_lead_provider
      @active_lead_provider ||= lead_provider.active_lead_providers.find_by(contract_period_year: contract_period.year)
    end

    def participant_status
      API::TrainingPeriods::TeacherStatus.new(latest_training_period: training_period, teacher:)
    end

    def ect_moving_to_reduced_schedule?
      training_period.for_ect? && schedule&.reduced_schedule?
    end

    def future_training_periods
      periods = training_period.for_mentor? ? teacher.mentor_training_periods : teacher.ect_training_periods

      periods.started_after(training_period.started_on)
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
