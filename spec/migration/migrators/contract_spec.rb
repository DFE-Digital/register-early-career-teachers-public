describe Migrators::Contract do
  it_behaves_like "a migrator", :contract, %i[active_lead_provider] do
    let(:cpd_lead_provider) { FactoryBot.create(:migration_cpd_lead_provider) }

    def create_ecf_call_off_contract(version:, cpd_lead_provider:, start_year:, mentor_funding: false)
      cohort = FactoryBot.create(:migration_cohort, start_year:, mentor_funding:)
      lead_provider = cpd_lead_provider.lead_provider

      statement = FactoryBot.create(:migration_statement, cpd_lead_provider:, cohort:, contract_version: version)

      # Ensure different versions result in different contract attributes.
      recruitment_target = version

      call_off_contract = FactoryBot.create(:migration_call_off_contract, recruitment_target:, cohort:, lead_provider:, version:).tap do |call_off_contract|
        FactoryBot.create(:migration_participant_band, call_off_contract:, min: 1, max: 10)
        FactoryBot.create(:migration_participant_band, call_off_contract:, min: 11, max: 20)
        FactoryBot.create(:migration_participant_band, call_off_contract:, min: 21, max: 30)
      end

      [call_off_contract, statement]
    end

    def create_ittecf_ectp_contract_resources(version:, mentor_version:, cpd_lead_provider:, start_year:)
      call_off_contract, statement = create_ecf_call_off_contract(version:, cpd_lead_provider:, start_year:, mentor_funding: true)
      mentor_call_off_contract = FactoryBot.create(
        :migration_mentor_call_off_contract,
        cohort: call_off_contract.cohort,
        lead_provider: call_off_contract.lead_provider,
        version: mentor_version
      )

      # Updates the statement we created for the call off contract.
      statement.update!(mentor_contract_version: mentor_version)

      [call_off_contract, mentor_call_off_contract]
    end

    def next_version
      ::Migration::CallOffContract.count + ::Migration::MentorCallOffContract.count + 1
    end

    def create_migration_resource
      call_off_contract, = create_ecf_call_off_contract(version: next_version, cpd_lead_provider:, start_year: 2024)
      call_off_contract
    end

    def create_resource(migration_resource)
      lead_provider = FactoryBot.create(:lead_provider, name: migration_resource.lead_provider.name, ecf_id: migration_resource.lead_provider.id)
      contract_period = FactoryBot.create(:contract_period, year: migration_resource.cohort.start_year, mentor_funding_enabled: migration_resource.cohort.mentor_funding?)
      FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
    end

    def setup_failure_state
      # Mentor funding with no mentor contract created.
      create_ecf_call_off_contract(version: "0", cpd_lead_provider:, start_year: 2023, mentor_funding: true)
    end

    describe "#migrate!" do
      it "creates the correct number of contracts" do
        expect { instance.migrate! }.to change(Contract, :count).by(2)
      end

      it "ignores unused contracts" do
        create_ecf_call_off_contract(version: "unused-v1", cpd_lead_provider:, start_year: 2024)

        expect { instance.migrate! }.to change(Contract, :count).by(2)
      end

      it "does not create duplicate contracts" do
        instance.migrate!
        expect { instance.migrate! }.not_to change(Contract, :count)
      end

      context "when a matching contract exists but for a different lead provider" do
        before do
          other_cpd_lead_provider = FactoryBot.create(:migration_cpd_lead_provider)
          call_off_contract, = create_ecf_call_off_contract(version: Migration::CallOffContract.first.version, cpd_lead_provider: other_cpd_lead_provider, start_year: 2025)

          create_resource(call_off_contract)
        end

        it "creates a new contract" do
          expect { instance.migrate! }.to change(Contract, :count).by(3)
        end
      end

      context "when a matching contract exists but for a different contract period" do
        before do
          call_off_contract, = create_ecf_call_off_contract(version: Migration::CallOffContract.first.version, cpd_lead_provider:, start_year: 2023)
          create_resource(call_off_contract)
        end

        it "creates a new contract" do
          expect { instance.migrate! }.to change(Contract, :count).by(3)
        end
      end

      context "when we encounter inconsistent call off contract -> mentor call off contract pairings" do
        before do
          version1 = "bad-shape-1"
          version2 = "bad-shape-2"

          contracts1 = create_ittecf_ectp_contract_resources(version: version1, mentor_version: version1, cpd_lead_provider:, start_year: 2025)
          contracts2 = create_ittecf_ectp_contract_resources(version: version1, mentor_version: version2, cpd_lead_provider:, start_year: 2025)

          (contracts1 + contracts2).each(&method(:create_resource))
        end

        it "increments the failure/processed counts and logs the failure" do
          expect { instance.migrate! }.to change { data_migration.reload.failure_count }.by_at_least(1)
          expect(failure_manager).to have_received(:record_failure).with(be_a(Migration::CallOffContract), "Unable to match call off contract with unique mentor call off contract!").at_least(:once)
        end
      end

      it "sets the ECF contract attributes correctly" do
        instance.migrate!

        contract = Contract.find_by!(contract_type: "ecf", ecf_contract_version: "1")
        banded_fee_structure = contract.banded_fee_structure
        bands = banded_fee_structure.bands

        ecf_call_off_contract = migration_resource1

        aggregate_failures do
          expect(contract.active_lead_provider.lead_provider.ecf_id).to eq(ecf_call_off_contract.lead_provider.id)
          expect(contract.active_lead_provider.contract_period_year).to eq(ecf_call_off_contract.cohort.start_year)

          expect(contract.contract_type).to eq("ecf")

          expect(banded_fee_structure).to have_attributes(ecf_call_off_contract.attributes.slice(described_class::BANDED_FEE_STRUCTURE_ATTRIBUTES))
          ecf_call_off_contract.participant_bands.each_with_index do |ecf_band, index|
            expect(bands[index]).to have_attributes(ecf_band.attributes.slice(described_class::BAND_ATTRIBUTES))
          end
        end
      end

      it "sets the ITTECF ECTP contract attributes correctly" do
        version = next_version
        ecf_call_off_contract, ecf_mentor_call_off_contract = create_ittecf_ectp_contract_resources(version:, mentor_version: version, cpd_lead_provider:, start_year: 2025)

        [ecf_call_off_contract, ecf_mentor_call_off_contract].each(&method(:create_resource))

        instance.migrate!

        contract = Contract.find_by!(contract_type: "ittecf_ectp", ecf_contract_version: ecf_call_off_contract.version, ecf_mentor_contract_version: ecf_mentor_call_off_contract.version)
        flat_rate_fee_structure = contract.flat_rate_fee_structure
        banded_fee_structure = contract.banded_fee_structure
        bands = banded_fee_structure.bands

        aggregate_failures do
          expect(contract.active_lead_provider.lead_provider.ecf_id).to eq(ecf_call_off_contract.lead_provider.id)
          expect(contract.active_lead_provider.contract_period_year).to eq(ecf_call_off_contract.cohort.start_year)

          expect(contract.contract_type).to eq("ittecf_ectp")

          expect(flat_rate_fee_structure).to have_attributes(ecf_mentor_call_off_contract.attributes.slice(*described_class::FLAT_RATE_FEE_STRUCTURE_ATTRIBUTES))
          expect(banded_fee_structure).to have_attributes(ecf_call_off_contract.attributes.slice(described_class::BANDED_FEE_STRUCTURE_ATTRIBUTES))
          ecf_call_off_contract.participant_bands.each_with_index do |ecf_band, index|
            expect(bands[index]).to have_attributes(ecf_band.attributes.slice(described_class::BAND_ATTRIBUTES))
          end
        end
      end
    end
  end
end
