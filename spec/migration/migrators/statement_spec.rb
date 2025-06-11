describe Migrators::Statement do
  it_behaves_like "a migrator", :statement, %i[lead_provider registration_period] do
    def create_migration_resource
      FactoryBot.create(:migration_statement, name: "February 2025")
    end

    def create_resource(migration_resource)
      lead_provider = FactoryBot.create(:lead_provider, name: migration_resource.lead_provider.name, api_id: migration_resource.lead_provider.id)
      registration_period = FactoryBot.create(:registration_period, year: migration_resource.cohort.start_year)
      active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, registration_period:)

      FactoryBot.create(:statement, active_lead_provider:)
    end

    def setup_failure_state
      # Statement to be migrated with no output_fee.
      migration_statement = FactoryBot.create(:migration_statement, output_fee: nil)
      FactoryBot.create(:lead_provider, name: migration_statement.lead_provider.name, api_id: migration_statement.lead_provider.id)
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
