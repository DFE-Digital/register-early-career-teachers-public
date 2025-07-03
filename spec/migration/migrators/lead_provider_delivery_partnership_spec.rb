describe Migrators::LeadProviderDeliveryPartnership do
  it_behaves_like "a migrator", :lead_provider_delivery_partnership, %i[contract_period active_lead_provider delivery_partner] do
    def create_migration_resource
      FactoryBot.create(:migration_provider_relationship)
    end

    def create_resource(migration_resource)
      cohort = migration_resource.cohort
      lp = migration_resource.lead_provider
      dp = migration_resource.delivery_partner

      contract_period = FactoryBot.create(:contract_period, year: cohort.start_year)
      lead_provider = FactoryBot.create(:lead_provider, name: lp.name, ecf_id: lp.id)
      FactoryBot.create(:delivery_partner, name: dp.name, api_id: dp.id)
      FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
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
          delivery_partner = DeliveryPartner.find_by!(api_id: provider_relationship.delivery_partner_id)
          contract_period = ContractPeriod.find(provider_relationship.cohort.start_year)

          active_lead_provider = ActiveLeadProvider.find_by!(lead_provider:, contract_period:)

          lpdp = LeadProviderDeliveryPartnership.find_by!(ecf_id: provider_relationship.id)
          expect(lpdp.active_lead_provider).to eq(active_lead_provider)
          expect(lpdp.delivery_partner).to eq(delivery_partner)
          expect(lpdp.created_at).to eq provider_relationship.created_at
          expect(lpdp.updated_at).to eq provider_relationship.updated_at
        end
      end
    end
  end
end
