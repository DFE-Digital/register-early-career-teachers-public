module SandboxSeedData
  class DeliveryPartners < Base
    NUMBER_OF_RECORDS_PER_LEAD_PROVIDER = 5

    def plant
      return unless plantable?

      log_plant_info("delivery partners")

      create_delivery_partners
    end

  private

    def create_delivery_partners
      ActiveLeadProvider.find_each do |active_lead_provider|
        NUMBER_OF_RECORDS_PER_LEAD_PROVIDER.times do
          delivery_partner = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:).delivery_partner

          log_seed_info("#{delivery_partner.name} -> #{active_lead_provider.lead_provider.name} / #{active_lead_provider.contract_period_year}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end
  end
end
