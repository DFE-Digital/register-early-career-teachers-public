module APISeedData
  class Schools < Base
    NUMBER_OF_RECORDS = 50
    SCHOOL_TYPES = %i[independent state_funded eligible ineligible].freeze
    PUPIL_PREMIUM_UPLIFT_RATIO = 0.15
    SPARSITY_UPLIFT_RATIO = 0.20

    def plant
      return unless plantable?

      log_plant_info("schools")

      NUMBER_OF_RECORDS.times do
        school = create_school(urn: Helpers::SchoolURNGenerator.next)

        set_school_funding_eligibility_for(school)

        log_seed_info("#{school.name} - type: #{school.type_name}", colour: Colourize::COLOURS.keys.sample)
      end
    end

  private

    def create_school(urn:)
      school_type = SCHOOL_TYPES.sample

      FactoryBot.create(:school, :with_induction_tutor, school_type, urn:)
    end

    def set_school_funding_eligibility_for(school)
      return unless school && Faker::Boolean.boolean(true_ratio: 0.7)

      ContractPeriod.find_each do |contract_period|
        FactoryBot.create(:school_funding_eligibility,
                          sparsity_uplift: contract_period.uplift_fees_enabled? ? Faker::Boolean.boolean(true_ratio: SPARSITY_UPLIFT_RATIO) : false,
                          pupil_premium_uplift: contract_period.uplift_fees_enabled? ? Faker::Boolean.boolean(true_ratio: PUPIL_PREMIUM_UPLIFT_RATIO) : false,
                          contract_period:,
                          school:)
      end
    end
  end
end
