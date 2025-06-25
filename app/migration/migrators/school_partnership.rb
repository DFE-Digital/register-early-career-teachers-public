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
      %i[lead_provider_delivery_partnership]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::SchoolPartnership.connection.execute("TRUNCATE #{::SchoolPartnership.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.partnerships.includes(:lead_provider, :delivery_partner, :cohort, :school)) do |partnership|
        lead_provider = ::LeadProvider.find_by!(ecf_id: partnership.lead_provider_id)
        delivery_partner = ::DeliveryPartner.find_by!(api_id: partnership.delivery_partner_id)
        registration_period = ::RegistrationPeriod.find(partnership.cohort.start_year)
        active_lead_provider = ::ActiveLeadProvider.find_by!(lead_provider:, registration_period:)
        lpdp = ::LeadProviderDeliveryPartnership.find_by!(active_lead_provider:, delivery_partner:)
        school_partnership = ::SchoolPartnership.find_or_initialize_by(api_id: partnership.id)

        school_partnership.lead_provider_delivery_partnership = lpdp
        school_partnership.school = ::School.find_by!(urn: partnership.school.urn)
        school_partnership.save!
      end
    end
  end
end
