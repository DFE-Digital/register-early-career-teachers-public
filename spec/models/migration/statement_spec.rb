describe Migration::Statement, type: :model do
  let(:cpd_lead_provider) { FactoryBot.create(:migration_cpd_lead_provider) }
  let(:lead_provider) { cpd_lead_provider.lead_provider }
  let(:instance) { FactoryBot.create(:migration_statement, cpd_lead_provider:) }

  describe "associations" do
    it { is_expected.to belong_to(:cpd_lead_provider) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to have_one(:lead_provider).through(:cpd_lead_provider) }
  end

  describe "#sanitized_mentor_contract_version" do
    subject { instance.sanitized_mentor_contract_version }

    let(:instance) { FactoryBot.create(:migration_statement, cpd_lead_provider:, mentor_contract_version: "123", cohort: FactoryBot.create(:migration_cohort, mentor_funding:)) }

    context "when the cohort has mentor funding" do
      let(:mentor_funding) { true }

      it { is_expected.to eq("123") }
    end

    context "when the cohort does not have mentor funding" do
      let(:mentor_funding) { false }

      it { is_expected.to be_nil }
    end
  end

  describe "#contract" do
    subject { instance.contract }

    let!(:contract) { FactoryBot.create(:migration_call_off_contract, cohort: instance.cohort, lead_provider:, version: instance.contract_version) }

    before do
      FactoryBot.create(:migration_call_off_contract, cohort: instance.cohort, lead_provider: FactoryBot.create(:migration_lead_provider), version: instance.contract_version)
      FactoryBot.create(:migration_call_off_contract, cohort: FactoryBot.create(:migration_cohort, start_year: instance.cohort.start_year - 1), lead_provider: instance.lead_provider, version: instance.contract_version)
      FactoryBot.create(:migration_call_off_contract, cohort: instance.cohort, lead_provider:, version: "other_version")
    end

    it { is_expected.to eq(contract) }
  end

  describe "#mentor_contract" do
    subject { instance.mentor_contract }

    let!(:mentor_contract) { FactoryBot.create(:migration_mentor_call_off_contract, cohort: instance.cohort, lead_provider:, version: instance.mentor_contract_version) }

    before do
      FactoryBot.create(:migration_mentor_call_off_contract, cohort: instance.cohort, lead_provider: FactoryBot.create(:migration_lead_provider), version: instance.mentor_contract_version)
      FactoryBot.create(:migration_mentor_call_off_contract, cohort: FactoryBot.create(:migration_cohort, start_year: instance.cohort.start_year - 1), lead_provider: instance.lead_provider, version: instance.mentor_contract_version)
      FactoryBot.create(:migration_mentor_call_off_contract, cohort: instance.cohort, lead_provider:, version: "other_version")
    end

    it { is_expected.to eq(mentor_contract) }
  end
end
