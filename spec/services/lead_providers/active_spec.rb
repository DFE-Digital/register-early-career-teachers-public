describe LeadProviders::Active do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  describe "initialization" do
    it "is initialized with a lead provider" do
      service = LeadProviders::Active.new(lead_provider)

      expect(service.lead_provider).to eql(lead_provider)
    end
  end

  describe "#active_in_contract_period?" do
    subject { LeadProviders::Active.new(lead_provider).active_in_contract_period?(contract_period) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period) }

    context "when a framework_agreement record exists for the contract period" do
      let!(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period:) }

      it { is_expected.to be(true) }
    end

    context "when no framework_agreement record exists for the contract period" do
      it { is_expected.to be(false) }
    end
  end

  describe "#framework_agreements" do
    subject { LeadProviders::Active.new(lead_provider).framework_agreements(contract_period) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period) }
    let(:another_contract_period) { FactoryBot.create(:contract_period) }

    context "when a framework_agreement record exists for the contract period" do
      let!(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period:) }
      let!(:framework_agreement_in_another_contact_period) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period: another_contract_period) }

      it { is_expected.to include(framework_agreement) }
      it { is_expected.not_to include(framework_agreement_in_another_contact_period) }
    end

    context "when no framework_agreement record exists for the contract period" do
      it { is_expected.to be_empty }
    end
  end

  describe ".in_contract_period" do
    subject { described_class.in_contract_period(contract_period) }

    let(:contract_period) { FactoryBot.create(:contract_period) }
    let!(:included_lp) { FactoryBot.create(:lead_provider) }
    let!(:excluded_lp) { FactoryBot.create(:lead_provider) }

    before do
      FactoryBot.create(:framework_agreement, lead_provider: included_lp, contract_period:)
    end

    it "returns only lead providers active in the given contract period" do
      expect(subject).to include(included_lp)
      expect(subject).not_to include(excluded_lp)
    end
  end
end
