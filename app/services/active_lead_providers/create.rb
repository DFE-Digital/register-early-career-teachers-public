# Builds an active lead provider for a contract period and, once saved, seeds it
# from the previous contract period (see SeedFromPrevious). Returns the active
# lead provider so callers can inspect validation errors when it isn't persisted;
# SeedFromPrevious errors are allowed to propagate.
class ActiveLeadProviders::Create
  attr_reader :active_lead_provider

  def initialize(author:, contract_period:, lead_provider_id:)
    @author = author
    @contract_period = contract_period
    @lead_provider_id = lead_provider_id
  end

  def call
    @active_lead_provider = contract_period.active_lead_providers.build(lead_provider_id:)

    if active_lead_provider.save
      Events::Record.record_active_lead_provider_created_event!(author:, active_lead_provider:)
      ActiveLeadProviders::SeedFromPrevious.new(active_lead_provider:).call
    end

    active_lead_provider
  end

private

  attr_reader :author, :contract_period, :lead_provider_id
end
