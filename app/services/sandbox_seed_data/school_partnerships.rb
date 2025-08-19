module SandboxSeedData
  class SchoolPartnerships < Base
    NUMBER_OF_RECORDS_PER_PARTNERSHIP = 2

    def plant
      return unless plantable?

      log_plant_info("school partnerships")

      NUMBER_OF_RECORDS_PER_PARTNERSHIP.times do
        create_school_partnerships
      end
    end

  private

    def create_school_partnerships
      ids = LeadProviderDeliveryPartnership.pluck(:id)
      LeadProviderDeliveryPartnership.where(id: ids).find_each do |lead_provider_delivery_partnership|
        existing_school_ids = lead_provider_delivery_partnership.school_partnerships.pluck(:school_id)
        school = School.where.not(id: existing_school_ids).order("RANDOM()").first
        next unless school

        school_partnership = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)

        log_seed_info("#{school_partnership.school.name} -> #{school_partnership.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)

        # Create another school partnership with the same school but different delivery_partner
        if rand < 0.1
          active_lead_provider = lead_provider_delivery_partnership.active_lead_provider

          lead_provider_delivery_partnership2 = LeadProviderDeliveryPartnership
            .where(active_lead_provider:)
            .where.not(delivery_partner: lead_provider_delivery_partnership.delivery_partner)
            .order("RANDOM()")
            .first
          next if SchoolPartnership.where(school:, lead_provider_delivery_partnership: lead_provider_delivery_partnership2).exists?

          school_partnership2 = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lead_provider_delivery_partnership2)
          log_seed_info("#{school_partnership2.school.name} -> #{school_partnership2.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end
  end
end
