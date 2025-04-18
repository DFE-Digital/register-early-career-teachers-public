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
        ::RegistrationPeriod.create!(id: cohort.start_year)
      end
    end
  end
end
