module TrainingPeriodSources
  extend ActiveSupport::Concern

  def contract_period
    @contract_period ||= ContractPeriod.containing_date(started_on)
  end

  def active_lead_provider
    @active_lead_provider ||= ActiveLeadProvider.find_by!(lead_provider:, contract_period:)
  end

  def earliest_matching_school_partnership
    SchoolPartnerships::Query.new(school:, lead_provider:, contract_period:)
    .earliest_school_partnership
  end

  def expression_of_interest
    earliest_matching_school_partnership ? nil : active_lead_provider
  end
end
