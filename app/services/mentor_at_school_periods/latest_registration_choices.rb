module MentorAtSchoolPeriods
  class LatestRegistrationChoices
    attr_reader :trn

    def initialize(trn:)
      @trn = trn
    end

    def training_period
      @training_period ||= ::TrainingPeriod
        .includes(mentor_at_school_period: [:teacher])
        .where(teacher: { trn: })
        .latest_first.first
    end

    delegate :school_partnership, to: :training_period, allow_nil: true
    delegate :school, :lead_provider, :delivery_partner, to: :school_partnership, allow_nil: true
  end
end
