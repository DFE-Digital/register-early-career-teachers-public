module Migrators
  class SchoolPartnership < Migrators::Base
    def self.record_count
      partnerships.count
    end

    def self.model
      :school_partnership
    end

    def self.partnerships
      ::Migration::Partnership.where(challenged_at: nil)
    end

    def self.dependencies
      # FIXME: add school in here as it might be needed but not currently migrated?
      %i[school lead_provider_delivery_partnership]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::SchoolPartnership.connection.execute("TRUNCATE #{::SchoolPartnership.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.partnerships.includes(:lead_provider, :delivery_partner, :cohort, :school)) do |partnership|
        migrate_one!(partnership)
      end
    end

    def migrate_one!(partnership)
      lead_provider = find_lead_provider_by_ecf_id!(partnership.lead_provider_id)
      delivery_partner = find_delivery_partner_by_api_id!(partnership.delivery_partner_id)
      contract_period = find_contract_period_by_year!(partnership.cohort.start_year)
      active_lead_provider_id = find_active_lead_provider_id!(lead_provider_id: lead_provider.id, contract_period_year: contract_period.year)
      lpdp = find_lead_provider_delivery_partnership_by_key!(active_lead_provider_id:, delivery_partner_id: delivery_partner.id)
      school_partnership = ::SchoolPartnership.find_or_initialize_by(api_id: partnership.id)

      school_partnership.lead_provider_delivery_partnership = lpdp
      school_partnership.school = find_school_by_urn!(partnership.school.urn)
      school_partnership.created_at = partnership.created_at
      school_partnership.api_updated_at = partnership.updated_at
      school_partnership.save!
      school_partnership
    end

  private

    def preload_caches
      cache_manager.cache_lead_providers_by_ecf_id
      cache_manager.cache_delivery_partners_by_api_id
      cache_manager.cache_contract_periods
      cache_manager.cache_active_lead_providers
      cache_manager.cache_lead_provider_delivery_partnerships
      cache_manager.cache_schools
    end
  end
end
