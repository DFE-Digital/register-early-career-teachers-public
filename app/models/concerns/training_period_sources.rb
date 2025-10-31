module TrainingPeriodSources
  extend ActiveSupport::Concern

  def contract_period
    @contract_period ||= ContractPeriod.containing_date(started_on)
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

  def reuse_old_partnership
    previous_id = @store&.school_partnership_to_reuse_id
    return nil if previous_id.blank?

    SchoolPartnerships::CreateFromPrevious
      .new.call(
        previous_school_partnership_id: previous_id,
        school:,
        author:,
        current_contract_period_year: contract_period.year
      )
  end
end
