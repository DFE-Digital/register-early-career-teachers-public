module MentorAtSchoolPeriods
  class LatestRegistrationChoices
    attr_reader :trn

    def initialize(trn:)
      @trn = trn
    end

    def training_period
      @training_period ||= ::TrainingPeriod.latest_for_mentor_trn(trn)
    end

    def confirmed_training_period
      @confirmed_training_period ||= ::TrainingPeriod.latest_confirmed_for_mentor_trn(trn)
    end

    def lead_provider
      school_partnership&.lead_provider || expression_of_interest&.lead_provider
    end

    def school
      school_partnership&.school || training_period&.mentor_at_school_period&.school
    end

  private

    delegate :delivery_partner, to: :school_partnership, allow_nil: true
    delegate :school_partnership, to: :training_period, allow_nil: true

    def expression_of_interest
      training_period&.expression_of_interest
    end
  end
end
