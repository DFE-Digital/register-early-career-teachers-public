module DeliveryPartners
  class AddLeadProviderPairings
    attr_reader :delivery_partner, :contract_period, :active_lead_provider_ids, :author

    def initialize(delivery_partner:, contract_period:, active_lead_provider_ids:, author:)
      @delivery_partner = delivery_partner
      @contract_period = contract_period
      @active_lead_provider_ids = active_lead_provider_ids
      @author = author
    end

    def add!
      ActiveRecord::Base.transaction do
        ids_to_add = active_lead_provider_ids_to_add
        add_partnerships(ids_to_add)
        true
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to add lead provider pairings: #{e.message}"
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

    def add_partnerships(ids_to_add)
      ids_to_add.each do |active_lead_provider_id|
        active_lead_provider = ActiveLeadProvider.find(active_lead_provider_id)
        LeadProviderDeliveryPartnerships::Create.new(
          author:,
          active_lead_provider:,
          params: { delivery_partner_id: delivery_partner.id }
        ).call
      end
    end
  end
end
