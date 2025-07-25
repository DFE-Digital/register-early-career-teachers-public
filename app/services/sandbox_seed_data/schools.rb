module SandboxSeedData
  class Schools < Base
    NUMBER_OF_SCHOOLS = 100
    SCHOOL_TYPES = %i[independent state_funded eligible ineligible cip_only not_cip_only].freeze

    def plant
      return unless plantable?

      log_plant_info("schools")

      NUMBER_OF_SCHOOLS.times do
        school = create_school(urn: Helpers::SchoolUrnGenerator.next)

        log_seed_info(Colourize.text(school.name, Colourize::COLOURS.keys.sample).to_s)
      end
    end

  private

    def create_school(urn:)
      school_type = SCHOOL_TYPES.sample
      school = FactoryBot.create(:school, SCHOOL_TYPES.sample, urn:)

      return school unless %i[eligible state_funded].include?(school_type)

      create_school_partnership(school)
      school
    end

    def create_school_partnership(school)
      lead_provider = LeadProvider.all.sample
      active_lead_provider = lead_provider.active_lead_providers.sample
      delivery_partner = FactoryBot.create(:delivery_partner, name: "Delivery Partner - #{active_lead_provider.contract_period_id} - #{SecureRandom.hex(4)}")
      lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
      FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)
    end
  end
end
