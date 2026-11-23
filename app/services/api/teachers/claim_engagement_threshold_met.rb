module API::Teachers
  class ClaimEngagementThresholdMet
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindLeadProvider
    include API::LeadProviderAuthor
    include API::FindTeacher
    include API::FindLatestTrainingPeriod

    attribute :lead_provider_id

    attribute :teacher_api_id
    attribute :teacher_type

    attribute :confirmation

    validates :confirmation, presence: { message: "Enter a '#/confirmation'." }
    validates :teacher_type, comparison: { equal_to: :ect, message: "'#/teacher_type' must be ECT" }
    validate :teacher_engagement_threshold_can_be_claimed, if: -> { errors.empty? }

    def claim_engagement_threshold_met
      return false unless valid?

      # maybe this would be in it's own service but a bit overkill
      ActiveRecord::Base.transaction do
        teacher.update!(ect_engagement_threshold_claimed: true)
        # TODO: log an event here
      end
    end

  private

    def teacher_engagement_threshold_can_be_claimed
      return errors.add(:teacher_api_id, "You cannot the claim engagement threshold is met for '#/teacher_api_id' because they are not training with you.") unless ect_training_periods.any?

      return errors.add(:teacher_api_id, "Engagement threshold has already been claimed for '#/teacher_api_id'.") if teacher.ect_engagement_threshold_claimed?

      return if has_started_declaration_in_correct_state?
      errors.add(:teacher_api_id, "The '#/teacher_api_id' did not start their training with you.")
    end

    def teacher
      @teacher ||= Teacher.find_by(api_id: teacher_api_id) if teacher_api_id
    end

    def ect_training_periods
      @training_periods ||= teacher.ect_training_periods.includes(:lead_provider).where(framework_agreement: { lead_provider: })
    end

    def has_started_declaration_in_correct_state?
      ect_training_periods.exists? { |tp| tp.declarations.where(declaration_type: :started, payment_status: %i[eligible payable paid]) }
    end
  end
end
