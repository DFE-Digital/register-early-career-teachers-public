module LeadProviderDeliveryPartnerships
  class Create
    attr_reader :lead_provider_delivery_partnership, :author

    def initialize(author:, active_lead_provider:, params:)
      @author = author
      @lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.new(
        params.merge(active_lead_provider:)
      )
    end

    def call
      ActiveRecord::Base.transaction do
        lead_provider_delivery_partnership.save!
        Events::Record.record_lead_provider_delivery_partnership_added_event!(
          author:,
          delivery_partner: lead_provider_delivery_partnership.delivery_partner,
          lead_provider: lead_provider_delivery_partnership.lead_provider,
          contract_period: lead_provider_delivery_partnership.contract_period,
          lead_provider_delivery_partnership:
        )
      end

      lead_provider_delivery_partnership
    end
  end
end
