module SandboxSeedData
  class Schools < Base
    NUMBER_OF_RECORDS = 100
    SCHOOL_TYPES = %i[independent state_funded eligible ineligible cip_only not_cip_only].freeze

    def plant
      return unless plantable?

      log_plant_info("schools")

      NUMBER_OF_RECORDS.times do
        create_school(urn: Helpers::SchoolUrnGenerator.next)
      end
    end

  private

    def create_school(urn:)
      school_type = SCHOOL_TYPES.sample
      school = FactoryBot.create(:school, school_type, urn:)

      log_seed_info("#{school.name} - type: #{school_type}", colour: Colourize::COLOURS.keys.sample)
    end
  end
end
