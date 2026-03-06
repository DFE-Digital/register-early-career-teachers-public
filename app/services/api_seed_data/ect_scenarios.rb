require Rails.root.join("db/seeds/support/mentorship_period_helpers")

module APISeedData
  class ECTScenarios < Base
    include MentorshipPeriodHelpers

    def plant
      return unless plantable?

      log_plant_info("api ect seed scenarios")

      ect_2025_with_2024_mentor
      ect_2025_with_2023_mentor
    end

    def ect_2025_with_2024_mentor
      ect_2025_with_previous_mentor(2024)
    end

    def ect_2025_with_2023_mentor
      ect_2025_with_previous_mentor(2023)
    end

  private

    def ect_2025_with_previous_mentor(mentor_year)
      contract_period_2025 = find_contract_period(2025)
      contract_period_mentor = find_contract_period(mentor_year)
      return unless contract_period_2025 && contract_period_mentor

      active_lead_providers.for_contract_period(contract_period_2025.year).each do |ect_active_lead_provider|
        mentor_active_lead_provider = active_lead_providers.for_contract_period(contract_period_mentor.year).for_lead_provider(ect_active_lead_provider.lead_provider_id).first
        school = find_school_with_partnerships_in_both_periods(mentor_active_lead_provider, ect_active_lead_provider)
        next unless school

        mentee_school_partnership = find_school_partnership_for(school, ect_active_lead_provider)
        mentor_school_partnership = find_school_partnership_for(school, mentor_active_lead_provider)
        next unless mentee_school_partnership && mentor_school_partnership

        mentorship_period = create_mentorship_period_for(
          mentee_school_partnership:,
          mentor_school_partnership:
        )

        log_seed_info("Created ECT (TRN: #{mentorship_period.mentee.teacher.trn}) from #{mentee_school_partnership.contract_period.year} with mentor from #{mentor_school_partnership.contract_period.year} with #{ect_active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
      end
    end

    def find_contract_period(year)
      ContractPeriod.find_by(year:)
    end

    def find_school_with_partnerships_in_both_periods(mentor_active_lead_provider, ect_active_lead_provider)
      mentor_schools = School
        .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
        .where(school_partnerships: { lead_provider_delivery_partnerships: { active_lead_provider: mentor_active_lead_provider } })
        .pluck(:id)

      ect_schools = School
        .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
        .where(school_partnerships: { lead_provider_delivery_partnerships: { active_lead_provider: ect_active_lead_provider } })
        .pluck(:id)

      School
        .where(id: mentor_schools & ect_schools)
        .order("RANDOM()")
        .first
    end

    def find_school_partnership_for(school, active_lead_provider)
      school
      .school_partnerships
      .includes(lead_provider_delivery_partnership: :active_lead_provider)
      .where(lead_provider_delivery_partnerships: { active_lead_provider: })
      .order("RANDOM()")
      .first
    end
  end
end
