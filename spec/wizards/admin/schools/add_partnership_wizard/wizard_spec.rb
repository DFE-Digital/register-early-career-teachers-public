RSpec.describe Admin::Schools::AddPartnershipWizard::Wizard do
  include DfE::Wizard::Test::RSpecMatchers

  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) do
    Admin::Schools::AddPartnershipWizard::StateStore.new(repository:)
  end
  let(:current_step) { :select_contract_period }
  let(:wizard) do
    described_class.new(
      state_store:,
      school_urn: "123456",
      author: nil,
      current_step:
    )
  end

  describe "flow" do
    it "starts by selecting a contract period" do
      expect(wizard).to have_root_step(:select_contract_period)
    end
  end

  describe "#allowed_steps" do
    subject { wizard.allowed_steps }

    context "when no data has been set yet" do
      it { is_expected.to eq([:select_contract_period]) }
    end

    context "when contract period is set" do
      before { state_store.write(contract_period_year: 2026) }

      it { is_expected.to include(:select_lead_provider) }
    end

    context "when lead provider is set" do
      before do
        state_store.write(contract_period_year: 2026, framework_agreement_id: 123)
      end

      it { is_expected.to include(:select_delivery_partner) }
    end

    context "when delivery partner is set" do
      before do
        state_store.write(
          contract_period_year: 2026,
          framework_agreement_id: 123,
          delivery_partner_id: 456
        )
      end

      it { is_expected.to include(:check_answers) }
    end
  end

  describe "#allowed_step?" do
    let(:current_step) { :select_lead_provider }

    it "returns true when current step is allowed" do
      state_store.write(contract_period_year: 2026)

      expect(wizard.allowed_step?).to be(true)
    end

    it "returns false when current step is not allowed" do
      expect(wizard.allowed_step?).to be(false)
    end
  end
end
