module TrainingPeriodSources
  extend ActiveSupport::Concern

  def contract_period
    @contract_period ||= ContractPeriod.current
  end

  def framework_agreement
    @framework_agreement ||= FrameworkAgreement.find_by!(lead_provider:, contract_period:)
  end

  def earliest_matching_school_partnership
    SchoolPartnerships::Search.new(school:, lead_provider:, contract_period:).school_partnerships.first
  end

  def expression_of_interest
    earliest_matching_school_partnership ? nil : framework_agreement
  end
end
