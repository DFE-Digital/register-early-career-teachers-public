describe Migrators::Statement do
  it_behaves_like "a migrator", :statement, %i[lead_provider registration_period active_lead_provider] do
    def create_migration_resource
      FactoryBot.create(:migration_statement, name: "February 2025")
    end

    def create_resource(migration_resource)
      # creating dependencies resources
      lead_provider = FactoryBot.create(:lead_provider, name: migration_resource.lead_provider.name, ecf_id: migration_resource.lead_provider.id)
      registration_period = FactoryBot.create(:registration_period, year: migration_resource.cohort.start_year)
      FactoryBot.create(:active_lead_provider, lead_provider:, registration_period:)

      FactoryBot.create(:statement)
    end

    def setup_failure_state
      # Record to be migrated with unmet dependencies in the destination db
      FactoryBot.create(:migration_statement)
    end

    describe "#migrate!" do
      it "sets the created statement attributes correctly" do
        instance.migrate!

        statement = Statement.find_by(api_id: migration_resource1.id)
        expect(statement).to have_attributes(migration_resource1.attributes.slice("deadline_date", "payment_date", "output_fee", "marked_as_paid_at", "created_at", "updated_at"))
        expect(statement.month).to eq(2)
        expect(statement.year).to eq(2025)
        expect(statement.registration_period.year).to eq(migration_resource1.cohort.start_year)
        expect(statement.lead_provider.name).to eq(migration_resource1.cpd_lead_provider.lead_provider.name)
        expect(statement.state).to eq("open")
      end
    end
  end
end
