module Migrators
  class LeadProviderDeliveryPartnership < Migrators::Base
    def self.record_count
      provider_relationships.count
    end

    def self.model
      :lead_provider_delivery_partnership
    end

    def self.provider_relationships
      ::Migration::ProviderRelationship.all
    end

    def self.dependencies
      %i[contract_period active_lead_provider delivery_partner]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::LeadProviderDeliveryPartnership.connection.execute("TRUNCATE #{::LeadProviderDeliveryPartnership.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.provider_relationships.includes(:lead_provider, :delivery_partner, :cohort)) do |provider_relationship|
        partnership = ::LeadProviderDeliveryPartnership.find_or_initialize_by(ecf_id: provider_relationship.id)
        partnership.active_lead_provider = ::ActiveLeadProvider.find_by!(
          lead_provider_id: ::LeadProvider.find_by!(ecf_id: provider_relationship.lead_provider_id),
          contract_period_id: ::ContractPeriod.find(provider_relationship.cohort.start_year)
        )
        partnership.delivery_partner = ::DeliveryPartner.find_by!(api_id: provider_relationship.delivery_partner_id)
        partnership.created_at = provider_relationship.created_at
        partnership.updated_at = provider_relationship.updated_at

        partnership.save!
      end
    end
  end
end
