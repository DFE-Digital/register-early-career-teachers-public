module Metadata
  class DeliveryPartnerLeadProvider < Metadata::Base
    self.table_name = :metadata_delivery_partners_lead_providers

    belongs_to :delivery_partner
    belongs_to :lead_provider

    validates :delivery_partner, presence: true
    validates :lead_provider, presence: true
    validates :contract_period_years,
              presence: true,
              inclusion: { in: (2021..Date.current.year).to_a }
    validates :contract_period_years, uniqueness: { scope: %i[delivery_partner_id lead_provider_id] }
  end
end
