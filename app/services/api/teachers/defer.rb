module API::Teachers
  class Defer
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindLeadProvider
    include API::LeadProviderAuthor
    include API::FindTeacher
    include API::FindLatestTrainingPeriod

    DEFERRAL_REASONS = TrainingPeriod.deferral_reasons.values.map(&:dasherize).freeze

    attribute :lead_provider_id

    attribute :teacher_api_id
    attribute :teacher_type

    attribute :reason

    validates :reason, presence: { message: "Enter a '#/reason'." },
                       inclusion: { in: DEFERRAL_REASONS,
                                    message: "The entered '#/reason' is not recognised for the given teacher. Check details and try again." }, if: -> { errors.empty? }

    validate :teacher_is_training_and_can_be_deferred, if: -> { errors.empty? }

    def defer
      return false if invalid?

      Teachers::Defer.new(
        author:,
        lead_provider:,
        reason:,
        teacher:,
        training_period:
      ).defer
    end

  private

    def teacher_is_training_and_can_be_deferred
      if training_status&.withdrawn?
        errors.add(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.")
      elsif training_status&.deferred?
        errors.add(:teacher_api_id, "The '#/teacher_api_id' is already deferred.")
      elsif training_period_has_not_yet_started?
        errors.add(:teacher_api_id, "You cannot defer #/teacher_api_id. This is because they have not been training with you for at least one day.")
      elsif training_period_started_today?
        errors.add(:teacher_api_id, "You cannot defer or withdraw this teacher today. You need to try again tomorrow as the training was recently changed for this teacher.")
      end
    end
  end
end
