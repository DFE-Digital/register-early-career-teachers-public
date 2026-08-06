module ActiveLeadProviders
  # Builds an active lead provider for a contract period and, once saved, seeds it
  # from the previous contract period (see SeedFromPrevious). Returns the active
  # lead provider so callers can inspect validation errors when it isn't persisted;
  # SeedFromPrevious errors are allowed to propagate.
  class Create < ApplicationService
    attribute :author
    attribute :contract_period
    attribute :lead_provider_id

    def call
      active_lead_provider = contract_period.active_lead_providers.build(lead_provider_id:)

      if active_lead_provider.save
        Events::Record.record_active_lead_provider_created_event!(author:, active_lead_provider:)
        SeedFromPrevious.(active_lead_provider:)
      end

      active_lead_provider
    end
  end
end
