module API::Teachers
  class Withdraw
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindLeadProvider
    include API::LeadProviderAuthor
    include API::FindTeacher
    include API::FindLatestTrainingPeriod

    WITHDRAWAL_REASONS = TrainingPeriod.withdrawal_reasons.values.map(&:dasherize).freeze
    MENTOR_ONLY_WITHDRAWAL_REASONS = TrainingPeriod::MENTOR_ONLY_WITHDRAWAL_REASONS.map(&:dasherize).freeze

    attribute :lead_provider_id

    attribute :teacher_api_id
    attribute :teacher_type

    attribute :reason

    validate :reason_is_valid_for_teacher_type
    validate :teacher_is_training_and_can_be_withdrawn, if: -> { errors.empty? }

    def withdraw
      return false unless valid?

      Teachers::Withdraw.new(
        author:,
        lead_provider:,
        reason:,
        teacher:,
        training_period:
      ).withdraw
    end

  private

    def reason_is_valid_for_teacher_type
      if reason.blank?
        errors.add(:reason, "Enter a '#/reason'.")
      elsif WITHDRAWAL_REASONS.exclude?(reason)
        errors.add(:reason, "The entered '#/reason' is not recognised for the given teacher. Check details and try again.")
      elsif training_period&.for_ect? && MENTOR_ONLY_WITHDRAWAL_REASONS.include?(reason)
        errors.add(:reason, "You cannot withdraw an ECT for this reason. The ECT is not a mentor.")
      end
    end

    def teacher_is_training_and_can_be_withdrawn
      if training_status&.withdrawn?
        errors.add(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.")
      elsif training_period_has_not_yet_started?
        errors.add(:teacher_api_id, "You cannot withdraw #/teacher_api_id. This is because they have not been training with you for at least one day.")
      elsif training_period_started_today?
        errors.add(:teacher_api_id, "You cannot defer or withdraw this teacher today. You need to try again tomorrow as the training was recently changed for this teacher.")
      end
    end
  end
end
