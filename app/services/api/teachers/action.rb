module API::Teachers
  class Action
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :author
    attribute :lead_provider_id
    attribute :participant_id
    attribute :course_identifier

    validates :lead_provider_id, presence: { message: "Your update cannot be made as the '#/lead_provider' is not recognised. Check lead provider details and try again." }
    validates :participant_id, presence: { message: "The property '#/participant_id' must be present" }
    validates :course_identifier,
              inclusion: { in: %w[ecf-mentor ecf-induction],
                           message: "The entered '#/course_identifier' is not recognised for the given participant. Check details and try again." },
              presence: { message: "Enter a '#/course_identifier' value for this participant." },
              allow_blank: false
    validate :teacher_exists
    validate :training_period_exists

    def teacher
      @teacher ||= Query.new(lead_provider_id:).teacher_by_api_id(participant_id)
    rescue ActiveRecord::RecordNotFound, ArgumentError
      nil
    end

    def latest_ect_training_period
      TrainingPeriod.ect_training_periods_latest_first(teacher:, lead_provider: lead_provider_id).first
    end

    def latest_mentor_training_period
      TrainingPeriod.mentor_training_periods_latest_first(teacher:, lead_provider: lead_provider_id).first
    end

    def training_period
      @training_period ||= if course_identifier == "ecf-induction"
                             latest_ect_training_period
                           elsif course_identifier == "ecf-mentor"
                             latest_mentor_training_period
                           end
    end

    def training_status
      @training_status ||= API::TrainingPeriods::TrainingStatus.new(training_period:).status
    end

  private

    def teacher_exists
      return if errors.any?
      return if teacher.present?

      errors.add(:participant_id, "Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.")
    end

    def training_period_exists
      return if errors.any?
      return if training_period.present?

      errors.add(:participant_id, "Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.")
    end
  end
end
