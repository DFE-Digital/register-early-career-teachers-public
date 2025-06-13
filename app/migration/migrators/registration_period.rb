module Migrators
  class RegistrationPeriod < Migrators::Base
    def self.record_count
      cohorts.count
    end

    def self.model
      :registration_period
    end

    def self.cohorts
      ::Migration::Cohort.all
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::RegistrationPeriod.connection.execute("TRUNCATE #{::RegistrationPeriod.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.cohorts) do |cohort|
        registration_period = ::RegistrationPeriod.find_or_initialize_by(year: cohort.start_year)

        registration_period.update!(
          started_on: cohort.registration_start_date,
          finished_on: finished_on_for(cohort),
          enabled: registration_period_enabled?(cohort),
          created_at: cohort.created_at,
          updated_at: cohort.updated_at
        )
      end
    end

  private

    def registration_period_enabled?(cohort)
      cohort.start_year.to_s != "2020" &&
        !(cohort.payments_frozen_at.present? && Time.current >= cohort.payments_frozen_at)
    end

    def finished_on_for(cohort)
      next_cohort = cohort.next

      return cohort.registration_start_date.next_year.prev_day if next_cohort.blank?

      next_cohort.registration_start_date.prev_day
    end
  end
end
