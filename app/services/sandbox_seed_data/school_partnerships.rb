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
      LeadProviderDeliveryPartnership.find_each do |lead_provider_delivery_partnership|
        school = School.order("RANDOM()").first

        next if school.school_partnerships.map(&:lead_provider_delivery_partnership).map(&:id).include?(lead_provider_delivery_partnership.id)

        school_partnership = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)

        log_seed_info("#{school_partnership.school.name} -> #{school_partnership.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
      end
    end
  end
end
