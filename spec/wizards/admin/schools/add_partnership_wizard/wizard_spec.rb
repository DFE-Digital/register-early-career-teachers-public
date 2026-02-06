RSpec.describe Admin::Schools::AddPartnershipWizard::Wizard do
  let(:store) { SessionRepository.new(session: {}, form_key: "test_form") }
  let(:school) { FactoryBot.create(:school) }
  let(:current_step) { :select_contract_period }
  let(:wizard) { described_class.new(store:, school_urn: school.urn, current_step:) }

  describe "#allowed_steps" do
    subject { wizard.allowed_steps }

    context "when no data has been set yet" do
      it { is_expected.to eq([:select_contract_period]) }
    end

    context "when contract period is set" do
      before { store.contract_period_year = 2026 }

      it { is_expected.to include(:select_lead_provider) }
    end

    context "when lead provider is set" do
      before do
        store.contract_period_year = 2026
        store.active_lead_provider_id = 123
      end

      it { is_expected.to include(:select_delivery_partner) }
    end

    context "when delivery partner is set" do
      before do
        store.contract_period_year = 2026
        store.active_lead_provider_id = 123
        store.delivery_partner_id = 456
      end

      it { is_expected.to include(:check_answers) }
    end
  end

  describe "#allowed_step?" do
    it "returns true when current step is allowed" do
      store.contract_period_year = 2026
      current_step = :select_lead_provider
      wizard = described_class.new(store:, school_urn: school.urn, current_step:)

      expect(wizard.allowed_step?).to be(true)
    end

    it "returns false when current step is not allowed" do
      current_step = :select_lead_provider
      wizard = described_class.new(store:, school_urn: school.urn, current_step:)

      expect(wizard.allowed_step?).to be(false)
    end
  end
end
