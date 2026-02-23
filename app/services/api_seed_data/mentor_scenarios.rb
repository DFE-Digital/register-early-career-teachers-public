module APISeedData
  class MentorScenarios < Base
    def plant
      return unless plantable?

      log_plant_info("api mentor seed scenarios")

      mentor_with_three_ects_2025
      mentor_with_two_ects_2024
    end

  private

    def mentor_with_three_ects_2025
      contract_period = find_contract_period(2025)
      return unless contract_period

      ActiveLeadProvider.for_contract_period(contract_period.year).each do |active_lead_provider|
        school_partnerships = find_school_partnerships(active_lead_provider)
        next if school_partnerships.count < 2

        school_a_partnership = school_partnerships.first
        school_b_partnership = school_partnerships.last

        mentor_start_date = Date.new(2025, 9, 1)
        schedule = find_schedule(contract_period)

        # Create mentor
        mentor_school_period = FactoryBot.create(
          :mentor_at_school_period,
          school: school_a_partnership.school,
          started_on: mentor_start_date
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          :provider_led,
          :ongoing,
          mentor_at_school_period: mentor_school_period,
          school_partnership: school_a_partnership,
          schedule:,
          started_on: mentor_start_date
        )

        # Create 1 ECT at school A
        ect_a_school_period = FactoryBot.create(
          :ect_at_school_period,
          school: school_a_partnership.school,
          started_on: mentor_start_date
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          :ongoing,
          ect_at_school_period: ect_a_school_period,
          school_partnership: school_a_partnership,
          schedule:,
          started_on: mentor_start_date
        )

        # Create 2 ECTs at school B
        2.times do
          ect_b_school_period = FactoryBot.create(
            :ect_at_school_period,
            school: school_b_partnership.school,
            started_on: mentor_start_date
          )

          FactoryBot.create(
            :training_period,
            :for_ect,
            :provider_led,
            :ongoing,
            ect_at_school_period: ect_b_school_period,
            school_partnership: school_b_partnership,
            schedule:,
            started_on: mentor_start_date
          )
        end

        log_seed_info("Created mentor with 3 ECTs (2025): 1 at school A, 2 at school B with #{active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
      end
    end

    def mentor_with_two_ects_2024
      contract_period = find_contract_period(2024)
      return unless contract_period

      ActiveLeadProvider.for_contract_period(contract_period.year).each do |active_lead_provider|
        school_partnerships = find_school_partnerships(active_lead_provider)
        next if school_partnerships.count < 2

        school_a_partnership = school_partnerships.first
        school_b_partnership = school_partnerships.last

        mentor_start_date = Date.new(2024, 9, 1)
        schedule = find_schedule(contract_period)

        # Create mentor
        mentor_school_period = FactoryBot.create(
          :mentor_at_school_period,
          school: school_a_partnership.school,
          started_on: mentor_start_date
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          :provider_led,
          :ongoing,
          mentor_at_school_period: mentor_school_period,
          school_partnership: school_a_partnership,
          schedule:,
          started_on: mentor_start_date
        )

        # Create 1 ECT at school A
        ect_a_school_period = FactoryBot.create(
          :ect_at_school_period,
          school: school_a_partnership.school,
          started_on: mentor_start_date
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          :ongoing,
          ect_at_school_period: ect_a_school_period,
          school_partnership: school_a_partnership,
          schedule:,
          started_on: mentor_start_date
        )

        # Create 1 ECT at school B
        ect_b_school_period = FactoryBot.create(
          :ect_at_school_period,
          school: school_b_partnership.school,
          started_on: mentor_start_date
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          :ongoing,
          ect_at_school_period: ect_b_school_period,
          school_partnership: school_b_partnership,
          schedule:,
          started_on: mentor_start_date
        )

        log_seed_info("Created mentor with 2 ECTs (2024): 1 at school A, 1 at school B with #{active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
      end
    end

    def find_contract_period(year)
      ContractPeriod.find_by(year:)
    end

    def find_school_partnerships(active_lead_provider)
      SchoolPartnership
        .includes(:lead_provider_delivery_partnership)
        .where(lead_provider_delivery_partnership: { active_lead_provider: })
        .order("RANDOM()")
        .limit(2)
    end

    def find_schedule(contract_period)
      if Faker::Boolean.boolean(true_ratio: 0.8)
        return Schedule.find_by(
          contract_period:,
          identifier: "ecf-standard-september"
        )
      end

      Schedule
        .excluding_replacement_schedules
        .where(contract_period:)
        .order(Arel.sql("RANDOM()"))
        .first
    end
  end
end
