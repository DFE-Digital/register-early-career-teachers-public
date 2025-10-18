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
      existing_metadata = Metadata::DeliveryPartnerLeadProvider
              .where(delivery_partner:, lead_provider_id: lead_provider_ids)
              .index_by(&:lead_provider_id)

      changes_to_upsert = []

      lead_provider_ids.each do |lead_provider_id|
        metadata = existing_metadata[lead_provider_id] ||
          Metadata::DeliveryPartnerLeadProvider.new(delivery_partner:, lead_provider_id:)

        changes = {
          delivery_partner_id: delivery_partner.id,
          lead_provider_id:,
          contract_period_years: contract_period_years_by_lead_provider[lead_provider_id] || []
        }

        next if metadata.attributes.slice(*changes.keys) == changes

        alert_on_changes(metadata:, changes:)
        changes_to_upsert << changes
      end

      Metadata::DeliveryPartnerLeadProvider.upsert_all(changes_to_upsert, unique_by: %i[delivery_partner_id lead_provider_id])
    end

    def contract_period_years_by_lead_provider
      @contract_period_years_by_lead_provider ||= delivery_partner
          .lead_provider_delivery_partnerships
          .joins(:active_lead_provider)
          .group("active_lead_providers.lead_provider_id")
          .pluck(
            Arel.sql("active_lead_providers.lead_provider_id"),
            Arel.sql("ARRAY_AGG(DISTINCT active_lead_providers.contract_period_year ORDER BY active_lead_providers.contract_period_year)")
          ).to_h
    end
  end
end
