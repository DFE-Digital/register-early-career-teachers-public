module API::Concerns::Teachers
  module SharedAction
    extend ActiveSupport::Concern

    TEACHER_TYPES = %i[ect mentor].freeze

    included do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :lead_provider_id
      attribute :teacher_api_id
      attribute :teacher_type

      validates :lead_provider_id, presence: { message: "Enter a '#/lead_provider_id'." }
      validate :lead_provider_exists

      validates :teacher_api_id, presence: { message: "Enter a '#/teacher_api_id'." }
      validate :teacher_exists

      validates :teacher_type, presence: { message: "Enter a '#/teacher_type'." }
      validates :teacher_type,
                inclusion: {
                  in: TEACHER_TYPES,
                  message: "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again."
                },
                allow_blank: true
      validate :teacher_type_exists
    end

  private

    def lead_provider
      @lead_provider ||= LeadProvider.find_by(id: lead_provider_id) if lead_provider_id
    end

    def teacher
      @teacher ||= Teacher.find_by(api_id: teacher_api_id) if teacher_api_id
    end

    def lead_provider_exists
      return if errors[:lead_provider_id].any?
      return if lead_provider

      errors.add(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.")
    end

    def teacher_exists
      return if errors[:teacher_api_id].any?
      return if teacher

      errors.add(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.")
    end

    def teacher_type_exists
      return if errors[:teacher_type].any?
      return if training_period

      errors.add(:teacher_type, "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again.")
    end

    def metadata
      if teacher && lead_provider
        @metadata ||= teacher
        .lead_provider_metadata
        .includes(
          latest_ect_training_period: {
            school_partnership: [
              { school: :school_funding_eligibilities },
              { lead_provider_delivery_partnership: :delivery_partner }
            ],
            ect_at_school_period: {
              school: [],
              teacher: { finished_induction_period: [], ect_at_school_periods: [] }
            },
            schedule: :contract_period,
            contract_period: [],
            lead_provider: [],
          },
          latest_ect_contract_period: [],
          latest_mentor_training_period: {
            school_partnership: [
              { school: :school_funding_eligibilities },
              { lead_provider_delivery_partnership: :delivery_partner }
            ],
            mentor_at_school_period: {
              school: [],
              teacher: { mentor_at_school_periods: [] }
            },
            schedule: :contract_period,
            contract_period: [],
            lead_provider: [],
          },
          latest_mentor_contract_period: []
        )
        .find_by(lead_provider_id:)
      end
    end

    def training_period
      return unless metadata

      @training_period ||= case teacher_type
                           when :ect
                             metadata.latest_ect_training_period
                           when :mentor
                             metadata.latest_mentor_training_period
                           end
    end

    def training_status
      @training_status ||= API::TrainingPeriods::TrainingStatus.new(training_period:) if training_period
    end
  end
end
