module LeadProviderDeliveryPartnerships
  class Destroy
    class DeletionError < StandardError; end

    attr_reader :lead_provider_delivery_partnership, :author

    def initialize(author:, lead_provider_delivery_partnership:)
      @author = author
      @lead_provider_delivery_partnership = lead_provider_delivery_partnership
    end

    def call
      raise DeletionError, "Cannot remove a delivery partner with school partnerships" if lead_provider_delivery_partnership.school_partnerships.any?

      delivery_partner = lead_provider_delivery_partnership.delivery_partner
      lead_provider = lead_provider_delivery_partnership.lead_provider
      contract_period = lead_provider_delivery_partnership.contract_period

      ActiveRecord::Base.transaction do
        Events::Record.record_lead_provider_delivery_partnership_removed_event!(
          author:,
          delivery_partner:,
          lead_provider:,
          contract_period:,
          lead_provider_delivery_partnership:
        )
        lead_provider_delivery_partnership.destroy!
      end

      true
    end
  end
end
