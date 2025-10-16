module Metadata::Handlers
  class DeliveryPartner < Base
    attr_reader :delivery_partner

    def initialize(delivery_partner)
      @delivery_partner = delivery_partner
    end

    def refresh_metadata!
      upsert_lead_provider_metadata!
    end

    class << self
      def destroy_all_metadata!
        truncate_models!(Metadata::DeliveryPartnerLeadProvider)
      end
    end

    private

    def upsert_lead_provider_metadata!
      lead_provider_ids.each do |lead_provider_id|
        metadata = Metadata::DeliveryPartnerLeadProvider.find_or_initialize_by(
          delivery_partner:,
          lead_provider_id:
        )

        upsert(metadata, contract_period_years: contract_period_years(lead_provider_id))
      end
    end

    def contract_period_years(lead_provider_id)
      delivery_partner
        .lead_provider_delivery_partnerships
        .joins(:active_lead_provider)
        .where(active_lead_providers: {lead_provider_id:})
        .pluck("active_lead_providers.contract_period_year")
    end
  end
end
