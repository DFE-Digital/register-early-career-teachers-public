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
      changes_to_upsert = lead_provider_ids.each_with_object({}) do |lead_provider_id, hash|
        metadata = existing_lead_provider_metadata[lead_provider_id] ||
          Metadata::DeliveryPartnerLeadProvider.new(delivery_partner:, lead_provider_id:)

        changes = {
          delivery_partner_id: delivery_partner.id,
          lead_provider_id:,
          contract_period_years: contract_period_years(lead_provider_id)
        }

        next unless changes?(metadata, changes)

        hash[metadata] = changes if changes?(metadata, changes)
      end

      upsert_all(model: Metadata::DeliveryPartnerLeadProvider, changes_to_upsert:, unique_by: %i[delivery_partner_id lead_provider_id])
    end

    def existing_lead_provider_metadata
      @existing_lead_provider_metadata ||= Metadata::DeliveryPartnerLeadProvider
        .where(delivery_partner:, lead_provider_id: lead_provider_ids)
        .index_by(&:lead_provider_id)
    end

    def contract_period_years(lead_provider_id)
      delivery_partner
        .lead_provider_delivery_partnerships
        .joins(:active_lead_provider)
        .where(active_lead_providers: { lead_provider_id: })
        .pluck("active_lead_providers.contract_period_year")
    end
  end
end
