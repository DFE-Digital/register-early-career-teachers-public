describe Migrators::LeadProviderDeliveryPartnership do
  it_behaves_like "a migrator", :lead_provider_delivery_partnership, %i[registration_period active_lead_provider delivery_partner] do
    def create_migration_resource
      FactoryBot.create(:migration_provider_relationship)
    end

    def create_resource(migration_resource)
      cohort = migration_resource.cohort
      lead_provider = migration_resource.lead_provider
      delivery_partner = migration_resource.delivery_partner

      FactoryBot.create(:registration_period, year: migration_resource.cohort.start_year)
      FactoryBot.create(:lead_provider, name: lead_provider.name, ecf_id: lead_provider.id)
      FactoryBot.create(:delivery_partner, name: delivery_partner.name, api_id: delivery_partner.id)
    end

    def setup_failure_state
      # create object without migrated dependencies
      create_migration_resource
    end

    describe "#migrate!" do
      it "sets the created attributes correctly" do
        instance.migrate!

        described_class.provider_relationships.find_each do |provider_relationship|

          lead_provider = LeadProvider.find_by!(ecf_id: provider_relationship.lead_provider_id)
          delivery_partner = DeliveryPartner.find_by!(ecf_id: provider_relationship.delivery_partner_id)
          registration_period = RegistrationPeriod.find(provider_relationship.cohort.start_year)

          active_lead_provider = ActiveLeadProvider.find_by!(lead_provider:, registration_period:)

          lpdp = LeadProviderDeliveryPartnership.find_by!(ecf_id: provider_relationship.id)
          expect(lpdp.active_lead_provider).to eq(active_lead_provider)
          expect(lpdp.delivery_partner).to eq(delivery_partner)
        end
      end
    end
  end
end
