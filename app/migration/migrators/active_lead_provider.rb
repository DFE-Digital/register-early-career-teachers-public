module Migrators
  class ActiveLeadProvider < Migrators::Base
    def self.record_count
      active_lead_providers.size
    end

    def self.model
      :active_lead_provider
    end

    def self.active_lead_providers
      ::Migration::LeadProvider.select("lead_providers.id, cohorts.start_year").joins(:cohorts).order(:start_year)
    end

    def self.dependencies
      %i[lead_provider registration_period]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::ActiveLeadProvider.connection.execute("TRUNCATE #{::ActiveLeadProvider.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.active_lead_providers) do |ecf_active_lead_provider|
        lead_provider_id = find_lead_provider_id!(ecf_id: ecf_active_lead_provider.id)

        ::ActiveLeadProvider.find_or_create_by!(
          lead_provider_id:,
          registration_period_id: ecf_active_lead_provider.start_year
        )
      end
    end
  end
end
