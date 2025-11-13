module Migrators
  class Milestone < Migrators::Base
    def self.record_count
      milestones.count
    end

    def self.model
      :milestone
    end

    def self.dependencies
      [:schedule]
    end

    def self.milestones
      ::Migration::Milestone.all
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Milestone.connection.execute("TRUNCATE #{::Milestone.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.milestones) do |ecf_milestone|
        migrate_one!(ecf_milestone)
      end
    end

    def migrate_one!(ecf_milestone)
      # Find the corresponding RECT schedule
      ecf_schedule = ecf_milestone.schedule
      rect_schedule = ::Schedule.find_by!(
        identifier: ecf_schedule.schedule_identifier,
        contract_period_year: ecf_schedule.cohort.start_year
      )

      milestone = ::Milestone.find_or_initialize_by(
        schedule_id: rect_schedule.id,
        declaration_type: ecf_milestone.declaration_type
      )

      milestone.update!(
        start_date: ecf_milestone.start_date,
        milestone_date: ecf_milestone.milestone_date,
        created_at: ecf_milestone.created_at,
        updated_at: ecf_milestone.updated_at
      )

      milestone
    end
  end
end
