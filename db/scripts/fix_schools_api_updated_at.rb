# We need to handle this manually to ensure the correct
# api_updated_at is pulled across from ECF.

Metadata::SchoolContractPeriod.bypass_update_restrictions do
  all_years = Migration::Cohort.pluck(:start_year)

  ecf_updated_at_by_urn = Migration::School
    .left_joins(school_cohorts: :cohort)
    .pluck(
      "schools.urn",
      "cohorts.start_year",
      "school_cohorts.updated_at",
      "schools.updated_at"
    )
    .group_by { |urn, _, _, _| urn } # Group by school URN.
    .transform_values do |rows|
      # Get the school's updated_at timestamp (it's the same for all rows)
      # so we just grab the first.
      school_updated_at = rows.first[3]

      # Ensure we have an entry for all cohort years.
      all_years.index_with do |year|
        # Find the row for the current year, if it exists.
        match = rows.find { |_, y, _, _| y == year }

        # If it exists, take the max of the school's updated_at and the school_cohort's updated_at.
        if match
          [match[2], school_updated_at].max
        else
          # If it doesn't exist, just use the school's updated_at.
          school_updated_at
        end
      end
    end

  School.includes(:contract_period_metadata).find_each do |school|
    ecf_updated_at_by_urn.fetch(school.urn.to_s, {}).each do |contract_period_year, school_cohort_updated_at|
      metadata = school.contract_period_metadata.find { it.contract_period_year == contract_period_year }
      metadata.update!(api_updated_at: school_cohort_updated_at)
    end
  end
end
