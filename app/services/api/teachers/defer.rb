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

    validate :reason_is_present_and_a_recognised_value
    validate :teacher_is_training_and_can_be_deferred

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

    ####################################################
    # reason validations
    #
    def reason_is_present_and_a_recognised_value
      return if errors.any?

      reason_is_not_blank
      reason_is_a_valid_deferral_reason
    end

    def reason_is_not_blank
      return if errors.any?
      return if reason.present?

      errors.add(:reason, "Enter a '#/reason'.")
    end

    def reason_is_a_valid_deferral_reason
      return if errors.any?
      return if DEFERRAL_REASONS.include?(reason)

      errors.add(:reason, "The entered '#/reason' is not recognised for the given teacher. Check details and try again.")
    end

    ####################################################
    # teacher_api_id validations
    #
    def teacher_is_training_and_can_be_deferred
      return if errors.any?

      not_already_withdrawn
      not_already_deferred
      training_period_has_started
      training_for_at_least_one_day
    end

    def not_already_withdrawn
      return if errors.any?
      return unless training_status&.withdrawn?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.")
    end

    def not_already_deferred
      return if errors.any?
      return unless training_status&.deferred?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already deferred.")
    end

    def training_period_has_started
      return if errors.any?
      return unless training_period&.started_on&.future?

      errors.add(:teacher_api_id, "You cannot defer #/teacher_api_id. This is because they have not been training with you for at least one day.")
    end

    def training_for_at_least_one_day
      return if errors.any?
      return unless training_period&.started_on&.today?

      errors.add(:teacher_api_id, "You cannot defer or withdraw this teacher today. You need to try again tomorrow as the training was recently changed for this teacher.")
    end
  end
end
