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
        ids_to_add = active_lead_provider_ids_to_add
        ids_to_remove = active_lead_provider_ids_to_remove

        remove_partnerships(ids_to_remove)
        add_partnerships(ids_to_add)
        true
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to update lead provider pairings: #{e.message}"
      false
    end

  private

    def current_partnerships
      @current_partnerships ||= delivery_partner
        .lead_provider_delivery_partnerships
        .for_contract_period(contract_period)
    end

    def current_active_lead_provider_ids
      @current_active_lead_provider_ids ||= current_partnerships.map(&:active_lead_provider_id)
    end

    def active_lead_provider_ids_to_add
      active_lead_provider_ids - current_active_lead_provider_ids
    end

    def active_lead_provider_ids_to_remove
      current_active_lead_provider_ids - active_lead_provider_ids
    end

    def add_partnerships(ids_to_add)
      ids_to_add.each do |active_lead_provider_id|
        active_lead_provider = ActiveLeadProvider.find(active_lead_provider_id)
        new_partnership = LeadProviderDeliveryPartnership.create!(
          delivery_partner:,
          active_lead_provider:
        )

        record_partnership_added_event(active_lead_provider, new_partnership)
      end
    end

    def remove_partnerships(ids_to_remove)
      ids_to_remove.each do |active_lead_provider_id|
        partnership = current_partnerships.find_by(active_lead_provider_id:)
        next unless partnership

        active_lead_provider = partnership.active_lead_provider

        record_partnership_removed_event(active_lead_provider, partnership)
        partnership.destroy!
      end
    end

    def record_partnership_added_event(active_lead_provider, new_partnership)
      Events::Record.record_lead_provider_delivery_partnership_added_event!(
        delivery_partner:,
        lead_provider: active_lead_provider.lead_provider,
        contract_period:,
        author:,
        lead_provider_delivery_partnership: new_partnership
      )
    end

    def record_partnership_removed_event(active_lead_provider, removed_partnership)
      Events::Record.record_lead_provider_delivery_partnership_removed_event!(
        delivery_partner:,
        lead_provider: active_lead_provider.lead_provider,
        contract_period:,
        author:,
        lead_provider_delivery_partnership: removed_partnership
      )
    end
  end
end
