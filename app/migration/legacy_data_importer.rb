class LegacyDataImporter
  def prepare!
    migrators.each(&:prepare!)
  end

  def migrate!
    migrators_in_dependency_order.each do |migrator|
      migrator.queue if migrator.runnable?
    end

    if DataMigration.incomplete.none?
      Metadata::SchoolContractPeriod.bypass_update_restrictions { create_schools_metadata }
      Metadata::Manager.refresh_all_metadata!(async: true, excluding_handlers: [Metadata::Handlers::School])
    end
  end

  def reset!
    # FIXME: could cause an issue if there are any jobs in process, plus do
    # we want to do this?
    DataMigration.all.find_each(&:destroy!)

    Metadata::Manager.destroy_all_metadata!

    migrators_in_dependency_order.reverse.each(&:reset!)
  end

private

  def migrators
    Migrators::Base.migrators
  end

  def migrators_in_dependency_order
    Migrators::Base.migrators_in_dependency_order
  end

  # We need to handle this manually to ensure the correct
  # api_updated_at is pulled across from ECF.
  def create_schools_metadata
    school_cohort_updated_at_by_school_urn = Migration::SchoolCohort
      .joins(:cohort, :school)
      .pluck("cohorts.start_year, schools.urn, school_cohorts.updated_at, schools.updated_at")
      .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |(cohort_start_year, school_urn, school_cohort_updated_at, school_updated_at), hash|
        hash[school_urn][cohort_start_year] = [school_cohort_updated_at, school_updated_at].max
      end

    School.includes(:contract_period_metadata).find_each do |school|
      Metadata::Manager.new.refresh_metadata!(school)

      school_cohort_updated_at_by_school_urn.fetch(school.urn.to_s, {}).each do |contract_period_year, school_cohort_updated_at|
        metadata = school.contract_period_metadata.reload.find { it.contract_period_year == contract_period_year }
        metadata.update!(api_updated_at: school_cohort_updated_at)
      end
    end
  end
end
