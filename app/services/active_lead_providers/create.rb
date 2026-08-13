# Builds an active lead provider for a contract period and, once saved, seeds it
# from the previous contract period (see SeedFromPrevious). Returns the active
# lead provider so callers can inspect validation errors when it isn't persisted;
# SeedFromPrevious errors are allowed to propagate.
class ActiveLeadProviders::Create
  attr_reader :framework_agreement

  def initialize(author:, contract_period:, lead_provider_id:)
    @author = author
    @contract_period = contract_period
    @lead_provider_id = lead_provider_id
  end

  def call
    @framework_agreement = contract_period.framework_agreements.build(lead_provider_id:)

    if framework_agreement.save
      Events::Record.record_active_lead_provider_created_event!(author:, framework_agreement:)
      ActiveLeadProviders::SeedFromPrevious.new(framework_agreement:).call
    end

    framework_agreement
  end

private

  attr_reader :author, :contract_period, :lead_provider_id
end
