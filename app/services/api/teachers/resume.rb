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

    validate :teacher_training_can_be_resumed

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

    def teacher_training_can_be_resumed
      return errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.") if training_status&.active?
      return errors.add(:teacher_api_id, "This teacher cannot be resumed because they are already active with another provider.") if unfinished_training_with_a_different_provider?
      return errors.add(:teacher_api_id, "You cannot resume a teacher on the same day they were withdrawn or deferred. Resume them tomorrow or later.") if training_period&.finished_on&.today?

      errors.add(:teacher_api_id, "The teacher is no longer at the school. Please contact the induction tutor to resolve.") if school_period&.finished?
    end

    def unfinished_training_with_a_different_provider?
      return false if training_period.blank?

      school_period.training_periods
        .contains_today
        .without(training_period)
        .exists?
    end

    def school_period
      @school_period ||= training_period&.at_school_period
    end
  end
end
