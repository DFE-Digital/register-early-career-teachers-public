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

      active_lead_providers.for_contract_period(contract_period.year).each do |active_lead_provider|
        school_partnerships = find_school_partnerships(active_lead_provider)
        next if school_partnerships.count < 2

        school_a_partnership = school_partnerships.first
        school_b_partnership = school_partnerships.last

        mentor = FactoryBot.create(:teacher, :with_realistic_name, trn: Helpers::TRNGenerator.next)

        # create open mentor_at_school_periods (2 total)
        mentor_school_period_a = create_open_mentor_school_period(mentor, school_a_partnership)
        mentor_school_period_b = create_open_mentor_school_period(mentor, school_b_partnership)

        # create one open mentor training period (at first school only)
        create_open_mentor_training_period(mentor_school_period_a, school_a_partnership)

        # create three concurrent ECTs
        create_open_ect_with_mentorship(mentor_school_period_a, school_a_partnership)
        create_open_ect_with_mentorship(mentor_school_period_b, school_b_partnership)
        create_open_ect_with_mentorship(mentor_school_period_b, school_b_partnership)

        log_seed_info(
          "Created mentor (TRN: #{mentor.trn}) with 3 concurrent ECTs (2025)",
          colour: Colourize::COLOURS.keys.sample
        )
      end
    end

    def mentor_with_two_ects_2024
      contract_period = find_contract_period(2024)
      return unless contract_period

      active_lead_providers.for_contract_period(contract_period.year).each do |active_lead_provider|
        school_partnerships = find_school_partnerships(active_lead_provider)
        next if school_partnerships.count < 2

        school_a_partnership = school_partnerships.first
        school_b_partnership = school_partnerships.last

        mentor = FactoryBot.create(:teacher, :with_realistic_name, trn: Helpers::TRNGenerator.next)

        # create two open mentor_at_school_periods
        mentor_school_period_a = create_open_mentor_school_period(mentor, school_a_partnership)
        mentor_school_period_b = create_open_mentor_school_period(mentor, school_b_partnership)

        # create one open mentor training period
        create_open_mentor_training_period(mentor_school_period_a, school_a_partnership)

        # create two concurrent ECTs
        create_open_ect_with_mentorship(mentor_school_period_a, school_a_partnership)
        create_open_ect_with_mentorship(mentor_school_period_b, school_b_partnership)

        log_seed_info(
          "Created mentor (TRN: #{mentor.trn}) with 2 concurrent ECTs (2024)",
          colour: Colourize::COLOURS.keys.sample
        )
      end
    end

    def create_open_mentor_school_period(mentor, school_partnership)
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        teacher: mentor,
        school: school_partnership.school
      )
    end

    def create_open_mentor_training_period(mentor_school_period, school_partnership)
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :ongoing,
        started_on: mentor_school_period.started_on,
        mentor_at_school_period: mentor_school_period,
        school_partnership:
      )
    end

    def create_open_ect_with_mentorship(mentor_school_period, school_partnership)
      mentee_school_period = FactoryBot.create(
        :ect_at_school_period,
        :ongoing,
        school: school_partnership.school
      )

      FactoryBot.create(
        :training_period,
        :for_ect,
        :ongoing,
        started_on: mentee_school_period.started_on,
        ect_at_school_period: mentee_school_period,
        school_partnership:
      )

      FactoryBot.create(
        :mentorship_period,
        :ongoing,
        mentee: mentee_school_period,
        mentor: mentor_school_period,
        started_on: mentor_school_period.started_on
      )
    end

    def find_contract_period(year)
      ContractPeriod.find_by(year:)
    end

    def find_school_partnerships(active_lead_provider)
      SchoolPartnership
        .includes(:lead_provider_delivery_partnership)
        .where(lead_provider_delivery_partnership: { active_lead_provider: })
        .to_a
        .uniq(&:school_id)
        .sample(2)
    end
  end
end
