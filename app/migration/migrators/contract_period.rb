module Migrators
  class ContractPeriod < Migrators::Base
    def self.record_count
      cohorts.count
    end

    def self.model
      :contract_period
    end

    def self.cohorts
      ::Migration::Cohort.all
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::ContractPeriod.connection.execute("TRUNCATE #{::ContractPeriod.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.cohorts) do |cohort|
        migrate_one!(cohort)
      end
    end

    def migrate_one!(cohort)
      contract_period = ::ContractPeriod.find_or_initialize_by(year: cohort.start_year)

      contract_period.update!(
        # dates
        started_on: cohort.registration_start_date,
        finished_on: finished_on_for(cohort),
        payments_frozen_at: cohort.payments_frozen_at,
        created_at: cohort.created_at,
        updated_at: cohort.updated_at,
        # flags
        detailed_evidence_types_enabled: cohort.detailed_evidence_types,
        mentor_funding_enabled: cohort.mentor_funding,
        uplift_fees_enabled: uplift_fees_enabled?(cohort),
        enabled: contract_period_enabled?(cohort)
      )

      contract_period
    end

  private

    def contract_period_enabled?(cohort)
      cohort.start_year.to_s != "2020" &&
        !(cohort.payments_frozen_at.present? && Time.current >= cohort.payments_frozen_at)
    end

    def uplift_fees_enabled?(cohort)
      cohort.start_year <= 2024
    end

    def finished_on_for(cohort)
      next_cohort = cohort.next

      return cohort.registration_start_date.next_year.prev_month.end_of_month if next_cohort.blank?

      next_cohort.registration_start_date.prev_day
    end
  end
end
