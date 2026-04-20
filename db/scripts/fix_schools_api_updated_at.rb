# We need to handle this manually to ensure the correct
# api_updated_at is pulled across from ECF.

Metadata::SchoolContractPeriod.bypass_update_restrictions do
  school_cohort_updated_at_by_school_urn = Migration::SchoolCohort
    .joins(:cohort, :school)
    .pluck("cohorts.start_year, schools.urn, school_cohorts.updated_at, schools.updated_at")
    .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |(cohort_start_year, school_urn, school_cohort_updated_at, school_updated_at), hash|
      hash[school_urn][cohort_start_year] = [school_cohort_updated_at, school_updated_at].max
    end

  School.includes(:contract_period_metadata).find_each do |school|
    school_cohort_updated_at_by_school_urn.fetch(school.urn.to_s, {}).each do |contract_period_year, school_cohort_updated_at|
      metadata = school.contract_period_metadata.find { it.contract_period_year == contract_period_year }
      metadata.update!(api_updated_at: school_cohort_updated_at)
    end
  end
end
