describe Migrators::Statement do
  it_behaves_like "a migrator", :statement, %i[lead_provider contract_period active_lead_provider contract] do
    def create_migration_resource
      cohort = FactoryBot.create(:migration_cohort, start_year: 2025, mentor_funding: true)
      FactoryBot.create(:migration_statement, name: "February 2025", cohort:, contract_version: "1", mentor_contract_version: "2").tap do |statement|
        FactoryBot.create(:migration_call_off_contract, lead_provider: statement.lead_provider, cohort: statement.cohort, version: "1")
        FactoryBot.create(:migration_mentor_call_off_contract, lead_provider: statement.lead_provider, cohort: statement.cohort, version: "2")
      end
    end

    def create_resource(migration_resource)
      # creating dependencies resources
      lead_provider = FactoryBot.create(:lead_provider, name: migration_resource.lead_provider.name, ecf_id: migration_resource.lead_provider.id)
      contract_period = FactoryBot.create(:contract_period, year: migration_resource.cohort.start_year, mentor_funding_enabled: migration_resource.cohort.mentor_funding)
      active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)

      contract_type = contract_period.mentor_funding_enabled ? :for_ittecf_ectp : :for_ecf
      ecf_contract_version = migration_resource.contract_version
      ecf_mentor_contract_version = migration_resource.mentor_contract_version
      FactoryBot.create(:contract, contract_type, active_lead_provider:, ecf_contract_version:, ecf_mentor_contract_version:)

      FactoryBot.create(:statement, active_lead_provider:)
    end

    def setup_failure_state
      # Record to be migrated with unmet dependencies in the destination db
      FactoryBot.create(:migration_statement)
    end

    describe "#migrate!" do
      it "sets the created statement attributes correctly" do
        instance.migrate!

        statement = Statement.find_by(api_id: migration_resource1.id)
        contract = Contract.find_by(ecf_contract_version: "1", ecf_mentor_contract_version: "2", contract_type: :ittecf_ectp)

        aggregate_failures do
          expect(statement).to have_attributes(migration_resource1.attributes.slice("deadline_date", "payment_date", "fee_type", "marked_as_paid_at", "created_at", "updated_at"))
          expect(statement.month).to eq(2)
          expect(statement.year).to eq(2025)
          expect(statement.contract_period.year).to eq(migration_resource1.cohort.start_year)
          expect(statement.lead_provider.name).to eq(migration_resource1.cpd_lead_provider.lead_provider.name)
          expect(statement.status).to eq("open")
          expect(statement.fee_type).to eq("output")
          expect(statement.contract).to eq(contract)
        end
      end

      it "migrates a statement with an 'ecf' contract type" do
        cohort = FactoryBot.create(:migration_cohort, start_year: 2024, mentor_funding: false)
        ecf_statement = FactoryBot.create(:migration_statement, name: "March 2025", cohort:, contract_version: "1", mentor_contract_version: nil).tap do |statement|
          FactoryBot.create(:migration_call_off_contract, lead_provider: statement.lead_provider, cohort: statement.cohort, version: "1")
        end
        create_resource(ecf_statement)

        instance.migrate!

        statement = Statement.find_by(api_id: ecf_statement.id)
        contract = Contract.find_by(ecf_contract_version: "1", contract_type: :ecf)

        expect(statement.contract).to eq(contract)
      end
    end
  end
end
