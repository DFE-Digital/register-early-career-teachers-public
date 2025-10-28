module API::Teachers
  class Resume
    include API::Concerns::Teachers::SharedAction

    validate :not_already_active_and_periods_open

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

    def not_already_active_and_periods_open
      return if errors[:teacher_api_id].any?

      is_active = training_status&.active?
      training_period_open = training_period.ongoing? || training_period.finished_on.future?
      at_school_period_open = training_period.trainee.ongoing?

      if is_active && training_period_open && at_school_period_open
        errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.")
      end
    end
  end
end
