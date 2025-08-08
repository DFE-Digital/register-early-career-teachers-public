module SandboxSeedData
  class DeliveryPartners < Base
    NUMBER_OF_RECORDS = 50

    def plant
      return unless plantable?

      log_plant_info("delivery partners")

      NUMBER_OF_RECORDS.times { create_delivery_partner }
    end

  private

    def create_delivery_partner
      delivery_partner = FactoryBot.build(:delivery_partner).tap do
        random_date = rand(1..100).days.ago
        it.update!(
          created_at: random_date,
          updated_at: random_date,
          api_updated_at: random_date
        )
      end

      log_seed_info(delivery_partner.name, indent: 2)
    end
  end
end
