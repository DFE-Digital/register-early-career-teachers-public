module TrainingPeriodSources
  extend ActiveSupport::Concern

  def contract_period
    @contract_period ||= ContractPeriod.containing_date(started_on)
  end

  def active_lead_provider
    @active_lead_provider ||= ActiveLeadProvider.find_by!(lead_provider:, contract_period:)
  end

  def school_partnership
    SchoolPartnership
      .joins(:lead_provider_delivery_partnership)
      .find_by(
        school:,
        lead_provider_delivery_partnerships: {
          active_lead_provider_id: active_lead_provider.id
        }
      )
  end

  def expression_of_interest
    school_partnership ? nil : active_lead_provider
  end
end
