require Rails.root.join("db/seeds/support/school_transfer_helpers")

module APISeedData
  class ECTAsMentorScenarios < Base
    include SchoolTransferHelpers

    def plant
      return unless plantable?

      log_plant_info("api mentor seed scenarios (ECTs who became mentors)")

      # 2x participants who completed 2022 ECT and then joined as a 2025 mentor
      ects_who_became_mentors(ect_year: 2022, mentor_year: 2025, count: 2)

      # 2x participants who completed 2023 ECT and then joined as a 2025 mentor
      ects_who_became_mentors(ect_year: 2023, mentor_year: 2025, count: 2)
    end

  private

    def ects_who_became_mentors(ect_year:, mentor_year:, count:)
      ect_contract_period = find_or_create_contract_period(ect_year)
      mentor_contract_period = find_or_create_contract_period(mentor_year)

      return unless ect_contract_period && mentor_contract_period

      LeadProvider.find_each do |lead_provider|
        existing_count = teachers_with_ect_and_mentor_training(
          lead_provider:,
          ect_year:,
          mentor_year:
        ).count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          teacher = FactoryBot.create(
            :teacher,
            :with_realistic_name,
            trn: Helpers::TRNGenerator.next,
            api_ect_training_record_id: SecureRandom.uuid,
            api_mentor_training_record_id: SecureRandom.uuid
          )

          create_completed_ect(
            teacher:,
            lead_provider:,
            ect_year:
          )

          create_ongoing_mentor(
            teacher:,
            lead_provider:,
            mentor_year:
          )

          log_seed_info(
            "Created #{teacher.trs_first_name} #{teacher.trs_last_name} - completed #{ect_year} ECT, now #{mentor_year} mentor with #{lead_provider.name}",
            colour: Colourize::COLOURS.keys.sample
          )
        end
      end
    end

    def create_completed_ect(teacher:, lead_provider:, ect_year:)
      started_on = Date.new(ect_year, 9, 1)
      finished_on = Date.new(ect_year + 2, 6, 30)

      ect_school_period = FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on:,
        finished_on:
      )

      school = ect_school_period.school

      school_partnership = school_partnership_between(
        lead_provider:,
        school:,
        from: started_on
      )

      FactoryBot.create(
        :training_period,
        :for_ect,
        :provider_led,
        :with_schedule,
        ect_at_school_period: ect_school_period,
        school_partnership:,
        started_on:,
        finished_on:
      )

      FactoryBot.create(
        :induction_period,
        :pass,
        teacher:,
        started_on:,
        finished_on:
      )
    end

    def create_ongoing_mentor(teacher:, lead_provider:, mentor_year:)
      started_on = Date.new(mentor_year, 9, 1)

      mentor_school_period = FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        teacher:,
        started_on:
      )

      school = mentor_school_period.school

      school_partnership = school_partnership_between(
        lead_provider:,
        school:,
        from: started_on
      )

      FactoryBot.create(
        :training_period,
        :for_mentor,
        :provider_led,
        :ongoing,
        :with_schedule,
        mentor_at_school_period: mentor_school_period,
        school_partnership:,
        started_on:
      )
    end

    def teachers_with_ect_and_mentor_training(lead_provider:, ect_year:, mentor_year:)
      teachers_with_ect = Teacher
        .joins(ect_at_school_periods: { training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } } })
        .where(active_lead_providers: { lead_provider_id: lead_provider.id })
        .where(training_periods: { started_on: Date.new(ect_year, 1, 1)..Date.new(ect_year, 12, 31) })
        .select(:id)

      Teacher
        .joins(mentor_at_school_periods: { training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } } })
        .where(active_lead_providers: { lead_provider_id: lead_provider.id })
        .where(training_periods: { started_on: Date.new(mentor_year, 1, 1)..Date.new(mentor_year, 12, 31) })
        .where(id: teachers_with_ect)
        .distinct
    end

    def find_or_create_contract_period(year)
      ContractPeriod.find_by(year:) ||
        FactoryBot.create(:contract_period, year:)
    end
  end
end
