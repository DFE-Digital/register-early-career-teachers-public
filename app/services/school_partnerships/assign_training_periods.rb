module SchoolPartnerships
  class AssignTrainingPeriods
    def initialize(school_partnership:, school:, lead_provider:, contract_period:)
      @school_partnership = school_partnership
      @school = school
      @lead_provider = lead_provider
      @contract_period = contract_period
    end

    def call
      TrainingPeriods::Search.new
        .linkable_to_school_partnership(
          school: @school,
          lead_provider: @lead_provider,
          contract_period: @contract_period
        )
        .find_each do |tp|
          tp.update!(school_partnership: @school_partnership)
        end
    end
  end
end
