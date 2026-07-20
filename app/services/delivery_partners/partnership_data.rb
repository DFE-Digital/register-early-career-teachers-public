module DeliveryPartners
  class PartnershipData
    attr_reader :delivery_partner, :all_contract_periods

    def initialize(delivery_partner)
      @delivery_partner = delivery_partner
      @all_contract_periods = ContractPeriod.all.latest_first.each_with_object({}) do |cp, h|
        h[cp.year] = []
      end
    end

    # returns a hash of contract_period years and lead provider names
    # { 2021 => ["Lead provider 1", "Lead provider 2"] }
    def partners_by_contract_period
      present = ContractPeriod
        .includes(active_lead_providers: [:lead_provider, { lead_provider_delivery_partnerships: :delivery_partner }])
        .where(active_lead_providers: { lead_provider_delivery_partnerships: { delivery_partner: } })
        .each_with_object({}) do |cp, h|
          h[cp.year] = cp.active_lead_providers.map { |alp| alp.lead_provider.name }.sort
        end

      { **all_contract_periods, **present }
    end
  end
end
