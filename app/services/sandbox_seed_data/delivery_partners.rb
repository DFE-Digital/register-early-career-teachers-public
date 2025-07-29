module SandboxSeedData
  class DeliveryPartners < Base
    NUMBER_OF_RECORDS = 50

    def plant
      return unless plantable?

      log_plant_info("delivery partners")

      NUMBER_OF_RECORDS.times do
        delivery_partner = create_delivery_partner

        log_seed_info(delivery_partner.name, colour: Colourize::COLOURS.keys.sample)
      end
    end

  private

    def create_delivery_partner
      lead_provider = LeadProvider.all.sample
      active_lead_provider = lead_provider.active_lead_providers.sample
      lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)

      lead_provider_delivery_partnership.delivery_partner
    end
  end
end
