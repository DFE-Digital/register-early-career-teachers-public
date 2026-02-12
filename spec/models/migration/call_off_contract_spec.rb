describe Migration::CallOffContract, type: :model do
  let(:cpd_lead_provider) { FactoryBot.create(:migration_cpd_lead_provider) }
  let(:instance) { FactoryBot.create(:migration_call_off_contract, lead_provider: cpd_lead_provider.lead_provider) }

  describe "associations" do
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to have_many(:participant_bands) }
  end

  describe "scopes" do
    describe ".not_flagged_as_unused" do
      subject { described_class.not_flagged_as_unused }

      let!(:used_contract) { FactoryBot.create(:migration_call_off_contract, version: "1") }

      before { FactoryBot.create(:migration_call_off_contract, version: "#{described_class::UNUSED_VERSION_PREFIX}_1") }

      it { is_expected.to contain_exactly(used_contract) }
    end
  end

  describe "#statements" do
    subject { instance.statements }

    let!(:statement) { FactoryBot.create(:migration_statement, cohort: instance.cohort, cpd_lead_provider:, contract_version: instance.version) }

    before do
      FactoryBot.create(:migration_statement, cohort: instance.cohort, cpd_lead_provider: FactoryBot.create(:migration_cpd_lead_provider), contract_version: instance.version)
      FactoryBot.create(:migration_statement, cohort: FactoryBot.create(:migration_cohort, start_year: instance.cohort.start_year - 1), cpd_lead_provider:, contract_version: instance.version)
      FactoryBot.create(:migration_statement, cohort: instance.cohort, cpd_lead_provider:, contract_version: "other_version_1")
    end

    it { is_expected.to contain_exactly(statement) }
  end

  describe "#attributes" do
    subject(:attributes) { instance.attributes }

    it "returns all the banded fee structure attributes we migrate" do
      expect(attributes.keys).to include(*Migrators::Contract::BANDED_FEE_STRUCTURE_ATTRIBUTES)
      expect(attributes.slice(*Migrators::Contract::BANDED_FEE_STRUCTURE_ATTRIBUTES)).to all(be_present)
    end
  end
end
