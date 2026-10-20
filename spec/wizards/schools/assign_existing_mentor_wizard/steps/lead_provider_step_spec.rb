RSpec.describe Schools::AssignExistingMentorWizard::Steps::LeadProviderStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Schools::AssignExistingMentorWizard::Wizard.new(
      state_store: Schools::AssignExistingMentorWizard::StateStore.new,
      current_step: :lead_provider,
      current_step_params: { lead_provider: { lead_provider_id: } }
    )
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:lead_provider_id) { lead_provider.id }

  describe "validations" do
    context "when lead_provider_id is not present" do
      let(:lead_provider_id) { nil }

      it { is_expected.to have_error(:lead_provider_id, "Select a lead provider to contact your school") }
    end

    context "when lead_provider_id does not match a lead provider" do
      let(:lead_provider_id) { lead_provider.id + 1 }

      it { is_expected.to have_error(:lead_provider_id, "Select a lead provider to contact your school") }
    end

    context "when lead_provider_id matches a lead provider" do
      it { is_expected.to be_valid }
    end
  end

  describe "#lead_provider" do
    it "is the selected lead provider" do
      expect(step.lead_provider).to eq(lead_provider)
    end
  end
end
