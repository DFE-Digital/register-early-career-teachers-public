module API::Teachers
  class Resume
    include API::Concerns::Teachers::SharedAction

    validate :not_already_active_or_periods_ongoing_today

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

    def not_already_active_or_periods_ongoing_today
      return if errors[:teacher_api_id].any?

      training_status_active = training_status&.active?
      training_period_ongoing = training_period.ongoing? || training_period.finished_on.future?
      at_school_period_ongoing = training_period.trainee.ongoing?

      if training_status_active && training_period_ongoing && at_school_period_ongoing
        errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.")
      end
    end
  end
end
