module APISeedData
  class SITBecomeMentorScenarios < Base
    def plant
      return unless plantable?

      log_plant_info("api mentor seed scenarios (SITs who became mentors and mentors who became SITs)")

      # SITs who became mentors
      # 2x mentors at 2022 partnership schools who were previously the SIT, now 2024 mentors
      update_mentors_to_match_sit(sit_year: 2022, mentor_year: 2024, count: 2)

      # 2x mentors at 2023 partnership schools who were previously the SIT, now 2025 mentors
      update_mentors_to_match_sit(sit_year: 2023, mentor_year: 2025, count: 2)

      # 2x mentors at 2025 partnership schools who were previously the SIT, now 2025 mentors
      update_mentors_to_match_sit(sit_year: 2025, mentor_year: 2025, count: 2)

      # Mentors who became SITs
      # 2x 2022 mentors who became 2024 SITs
      update_mentors_to_match_sit(mentor_year: 2022, sit_year: 2024, count: 2)

      # 2x 2023 mentors who became 2025 SITs
      update_mentors_to_match_sit(mentor_year: 2023, sit_year: 2025, count: 2)

      # 2x 2025 mentors who became 2025 SITs
      update_mentors_to_match_sit(mentor_year: 2025, sit_year: 2025, count: 2)
    end

  private

    def update_mentors_to_match_sit(sit_year:, mentor_year:, count:)
      count.times do
        lead_providers.find_each do |lead_provider|
          school_partnership = SchoolPartnership
            .joins(:school, lead_provider_delivery_partnership: :active_lead_provider)
            .where(active_lead_providers: { lead_provider_id: lead_provider.id, contract_period_year: sit_year })
            .where.not(schools: { induction_tutor_name: nil })
            .order("RANDOM()")
            .first

          next unless school_partnership

          school = school_partnership.school
          sit_name = school.induction_tutor_name

          parsed_name = ::Teachers::FullNameParser.new(full_name: sit_name)
          first_name = parsed_name.first_name
          last_name = parsed_name.last_name

          mentor_period = MentorAtSchoolPeriod
            .with_partnerships_for_contract_period(mentor_year)
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .includes(:teacher, :school)
            .order("RANDOM()")
            .first

          next unless mentor_period

          teacher = mentor_period.teacher
          teacher.update!(trs_first_name: first_name, trs_last_name: last_name)
          mentor_period.update!(email: school.induction_tutor_email)

          log_seed_info(
            "Updated mentor #{teacher.trn} to match SIT #{sit_name} at #{school.urn} - #{sit_year} SIT, #{mentor_year} mentor with #{lead_provider.name}",
            colour: Colourize::COLOURS.keys.sample
          )
        end
      end
    end
  end
end
