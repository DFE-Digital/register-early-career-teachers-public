module Migrators
  class PupilPremium < Migrators::Base
    def self.record_count
      pupil_premiums.size
    end

    def self.model
      :pupil_premium
    end

    def self.pupil_premiums
      Migration::PupilPremium.includes(:school).all
    end

    def self.dependencies
      %i[school contract_period]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Teacher.connection.execute("TRUNCATE #{::PupilPremium.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.pupil_premiums) do |pupil_premium|
        ::PupilPremium.find_or_create_by!(
          school_urn: pupil_premium.school.urn,
          contract_period_year: pupil_premium.start_year,
          pupil_premium_uplift: pupil_premium.pupil_premium_incentive,
          sparsity_uplift: pupil_premium.sparsity_incentive
        )
      end
    end
  end
end
