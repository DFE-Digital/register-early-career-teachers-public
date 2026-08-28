module API::Teachers
  class Resume
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindLeadProvider
    include API::LeadProviderAuthor
    include API::FindTeacher
    include API::FindLatestTrainingPeriod

    attribute :lead_provider_id

    attribute :teacher_api_id
    attribute :teacher_type

    validate :not_already_active
    validate :no_ongoing_today_training_period
    validate :training_period_not_finished_today
    validate :school_period_ongoing_today

    def resume
      return false unless valid?

      Teachers::Resume.new(
        author:,
        lead_provider:,
        teacher:,
        training_period:
      ).resume
    end

  private

    def training_period_not_finished_today
      return if errors[:teacher_api_id].any?
      return unless training_period_finished_today?

      errors.add(:teacher_api_id, "You cannot resume a participant on the same day they were withdrawn or deferred. Resume them tomorrow or later.")
    end

    def training_period_finished_today?
      training_period&.finished_on&.today?
    end

    def not_already_active
      return if errors[:teacher_api_id].any?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.") if training_status&.active?
    end

    def no_ongoing_today_training_period
      return if errors[:teacher_api_id].any?
      return unless training_period

      school_period = training_period.at_school_period

      if school_period.training_periods
        .contains_today
        .without(training_period)
        .exists?
        errors.add(:teacher_api_id, "This participant cannot be resumed because they are already active with another provider.")
      end
    end

    def school_period_ongoing_today
      return if errors[:teacher_api_id].any?
      return unless training_period

      school_period = training_period.at_school_period
      errors.add(:teacher_api_id, "The participant is no longer at the school. Please contact the induction tutor to resolve.") unless school_period.contains_today?
    end
  end
end
