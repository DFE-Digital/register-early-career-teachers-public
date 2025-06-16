RSpec.describe Migrators::LeadProvider do
  it_behaves_like "a migrator", :lead_provider, [] do
    def create_migration_resource
      FactoryBot.create(:migration_lead_provider)
    end

    def create_resource(migration_resource)
    end

    def setup_failure_state
      lp = FactoryBot.create(:migration_lead_provider)
      FactoryBot.create(:lead_provider, name: lp.name, api_id: SecureRandom.uuid)
    end

    describe "#migrate!" do
      it 'creates a record in the ecf2 database' do
        expect {
          instance.migrate!
        }.to change(::LeadProvider, :count).by(Migration::LeadProvider.count)
      end

      it "populates the ecf2 model correctly" do
        instance.migrate!

        ::LeadProvider.find_each do |lead_provider|
          source_record = Migration::LeadProvider.find(lead_provider.api_id)
          expect(lead_provider.name).to eq source_record.name
          expect(lead_provider.created_at).to eq source_record.created_at
          expect(lead_provider.updated_at).to eq source_record.updated_at
        end
      end
    end
  end
end
