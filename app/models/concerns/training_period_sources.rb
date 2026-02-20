module TrainingPeriodSources
  extend ActiveSupport::Concern

  # TO TEST FULLY
  def contract_period
    @contract_period ||= ContractPeriod.current_end_inclusive
  end

  def active_lead_provider
    @active_lead_provider ||= ActiveLeadProvider.find_by!(lead_provider:, contract_period:)
  end

  def earliest_matching_school_partnership
    SchoolPartnerships::Search.new(school:, lead_provider:, contract_period:).school_partnerships.first
  end

  def expression_of_interest
    earliest_matching_school_partnership ? nil : active_lead_provider
  end
end
