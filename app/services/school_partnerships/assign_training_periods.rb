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

          Events::Record.record_training_period_assigned_to_school_partnership_event!(
            author: Events::LeadProviderAPIAuthor.new(lead_provider: @lead_provider),
            training_period: tp,
            ect_at_school_period: tp.ect_at_school_period,
            mentor_at_school_period: tp.mentor_at_school_period,
            teacher: tp.ect_at_school_period&.teacher || tp.mentor_at_school_period&.teacher,
            school_partnership: @school_partnership,
            lead_provider: @lead_provider,
            delivery_partner: @school_partnership.delivery_partner,
            school: @school
          )
        end
    end
  end
end
