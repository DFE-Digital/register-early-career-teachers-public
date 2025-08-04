module DeliveryPartners
  class UpdateLeadProviderPairings
    attr_reader :delivery_partner, :contract_period, :active_lead_provider_ids, :author

    def initialize(delivery_partner:, contract_period:, active_lead_provider_ids:, author:)
      @delivery_partner = delivery_partner
      @contract_period = contract_period
      @active_lead_provider_ids = active_lead_provider_ids
      @author = author
    end

    def update!
      ActiveRecord::Base.transaction do
        # Get current partnerships for this delivery partner and contract period
        current_partnerships = delivery_partner
          .lead_provider_delivery_partnerships
          .joins(:active_lead_provider)
          .where(active_lead_providers: { contract_period_id: contract_period.id })

        current_active_lead_provider_ids = current_partnerships.map(&:active_lead_provider_id)

        # Find active lead provider IDs to add (those not currently associated)
        active_lead_provider_ids_to_add = active_lead_provider_ids - current_active_lead_provider_ids

        # Add new partnerships only
        active_lead_provider_ids_to_add.each do |active_lead_provider_id|
          active_lead_provider = ActiveLeadProvider.find(active_lead_provider_id)
          new_partnership = LeadProviderDeliveryPartnership.create!(
            delivery_partner:,
            active_lead_provider:
          )

          Events::Record.record_lead_provider_delivery_partnership_added_event!(
            delivery_partner:,
            lead_provider: active_lead_provider.lead_provider,
            contract_period:,
            author:,
            lead_provider_delivery_partnership: new_partnership
          )
        end

        true
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to update lead provider pairings: #{e.message}"
      false
    end
  end
end
