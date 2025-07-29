module SandboxSeedData
  class SchoolPartnerships < Base
    NUMBER_OF_RECORDS = 100

    def plant
      return unless plantable?

      log_plant_info("school partnerships")

      NUMBER_OF_RECORDS.times do
        school_partnership = create_school_partnership(school: School.order("RANDOM()").first)

        log_seed_info("#{school_partnership.school.name} -> #{school_partnership.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
      end
    end

  private

    def create_school_partnership(school:)
      lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.where.not(id: school.school_partnerships.map(&:lead_provider_delivery_partnership).map(&:id)).sample

      FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)
    end
  end
end
