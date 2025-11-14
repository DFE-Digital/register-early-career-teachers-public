module Migrators
  class Schedule < Migrators::Base
    def self.record_count
      schedules.count
    end

    def self.model
      :schedule
    end

    def self.dependencies
      [:contract_period]
    end

    def self.schedules
      ::Migration::Schedule.where(type: ["Finance::Schedule::ECF", "Finance::Schedule::Mentor"])
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Schedule.connection.execute("TRUNCATE #{::Schedule.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.schedules) do |ecf_schedule|
        migrate_one!(ecf_schedule)
      end
    end

    def migrate_one!(ecf_schedule)
      cohort = ecf_schedule.cohort
      contract_period = ::ContractPeriod.find_by!(year: cohort.start_year)

      schedule = ::Schedule.find_or_initialize_by(
        identifier: ecf_schedule.schedule_identifier,
        contract_period_year: contract_period.year
      )

      schedule.update!(
        created_at: ecf_schedule.created_at,
        updated_at: ecf_schedule.updated_at
      )

      schedule
    end
  end
end
