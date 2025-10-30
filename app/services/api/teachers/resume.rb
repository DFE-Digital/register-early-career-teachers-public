module API::Teachers
  class Resume
    include API::Concerns::Teachers::SharedAction

    validate :not_already_active
    validate :school_period_ongoing_today

    def resume
      return false unless valid?

      Teachers::Resume.new(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        lead_provider:,
        teacher:,
        training_period:
      ).resume
    end

  private

    def not_already_active
      return if errors[:teacher_api_id].any?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.") if training_status&.active?
    end

    def school_period_ongoing_today
      return if errors[:teacher_api_id].any?

      school_period = training_period.trainee
      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.") unless school_period.ongoing_today?
    end
  end
end
