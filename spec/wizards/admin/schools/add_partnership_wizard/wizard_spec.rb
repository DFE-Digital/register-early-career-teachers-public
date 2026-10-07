RSpec.describe Admin::Schools::AddPartnershipWizard::Wizard do
  include DfE::Wizard::Test::RSpecMatchers

  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) do
    Admin::Schools::AddPartnershipWizard::StateStore.new(
      school:,
      repository:
    )
  end

  let(:school) { FactoryBot.create(:school) }
  let(:contract_period) { FactoryBot.create(:contract_period) }
  let(:framework_agreement) do
    FactoryBot.create(:framework_agreement, contract_period:)
  end
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:lead_provider_delivery_partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      framework_agreement:,
      delivery_partner:
    )
  end

  let(:current_step) { :select_contract_period }
  let(:wizard) do
    described_class.new(
      state_store:,
      author: nil,
      current_step:
    )
  end

  describe "flow" do
    it "starts by selecting a contract period" do
      expect(wizard).to have_root_step(:select_contract_period)
    end
  end

  describe "#furthest_valid_step_path" do
    subject { wizard.furthest_valid_step_path }

    context "when no data has been set yet" do
      it { is_expected.to eq(path_for(:select_contract_period)) }
    end

    context "when a valid contract period is set" do
      before do
        state_store.write(contract_period_year: contract_period.year)
      end

      it { is_expected.to eq(path_for(:select_lead_provider)) }
    end

    context "when a valid lead provider is set" do
      before do
        state_store.write(
          contract_period_year: contract_period.year,
          framework_agreement_id: framework_agreement.id
        )
      end

      it { is_expected.to eq(path_for(:select_delivery_partner)) }
    end

    context "when a valid delivery partner is set" do
      before do
        lead_provider_delivery_partnership

        state_store.write(
          contract_period_year: contract_period.year,
          framework_agreement_id: framework_agreement.id,
          delivery_partner_id: delivery_partner.id
        )
      end

      it { is_expected.to eq(path_for(:check_answers)) }
    end
  end

  describe "#valid_path_to_current_step?" do
    subject { wizard.valid_path_to_current_step? }

    let(:current_step) { :select_lead_provider }

    context "when the contract period is valid" do
      before do
        state_store.write(contract_period_year: contract_period.year)
      end

      it { is_expected.to be(true) }
    end

    context "when the contract period is missing" do
      it { is_expected.to be(false) }
    end
  end

private

  def path_for(step)
    Rails.application.routes.url_helpers.public_send(
      "admin_schools_add_partnership_wizard_#{step}_path",
      school.urn
    )
  end
end
