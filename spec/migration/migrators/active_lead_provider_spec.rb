describe Migrators::ActiveLeadProvider do
  it_behaves_like "a migrator", :active_lead_provider, %i[lead_provider contract_period] do
    def create_migration_resource
      FactoryBot.create(:migration_lead_provider, :active)
    end

    def create_resource(migration_resource)
      # creating dependencies resources
      FactoryBot.create(:lead_provider, name: migration_resource.name, ecf_id: migration_resource.id)
      FactoryBot.create(:contract_period, year: migration_resource.cohorts.first.start_year)

      FactoryBot.create(:active_lead_provider)
    end

    def setup_failure_state
      # Record to be migrated with unmet dependencies in the destination db
      lead_provider = FactoryBot.create(:migration_lead_provider)
      lead_provider.cohorts << FactoryBot.create(:migration_cohort)
      lead_provider
    end

    describe "#migrate!" do
      it "sets the created record attributes correctly" do
        instance.migrate!

        active_lead_provider = ActiveLeadProvider.find_by(
          lead_provider_id: LeadProvider.find_by_ecf_id(migration_resource1.id).id,
          contract_period_id: migration_resource1.cohorts.first.start_year
        )
        expect(active_lead_provider).to be_present
      end
    end
  end
end
