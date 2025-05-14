module Teachers
  class PreviousECTRegistrationDetails
    def initialize(trn:)
      @teacher = Teacher.find_by(trn:)
    end

    def induction_start_date
      ::InductionPeriod
        .earliest_for_teacher(@teacher)
        .first
        &.started_on
    end

    def appropriate_body_name
      ::InductionPeriod
        .latest_for_teacher(@teacher)
        .includes(:appropriate_body)
        .first
        &.appropriate_body
        &.name
    end

    def training_programme
      ECTAtSchoolPeriod
        .latest_for_teacher(@teacher)
        .first
        &.programme_type
    end

    def provider_led?
      ECTAtSchoolPeriod.latest_for_teacher(@teacher).first&.provider_led_programme_type?
    end

    def lead_provider_name
      ::TrainingPeriod
        .latest_for_teacher(@teacher)
        .includes(:lead_provider)
        .first
        &.lead_provider
        &.name
    end

    def delivery_partner_name
      ::TrainingPeriod
        .latest_for_teacher(@teacher)
        .includes(:delivery_partner)
        .first
        &.delivery_partner
        &.name
    end
  end
end
