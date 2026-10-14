RSpec.describe Schools::AssignExistingMentorWizard::Steps::ReviewMentorEligibilityStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Schools::AssignExistingMentorWizard::Wizard.new(state_store:, current_step: :review_mentor_eligibility)
  end
  let(:state_store) { Schools::AssignExistingMentorWizard::StateStore.new }
  let(:ect_lead_provider) { FactoryBot.build_stubbed(:lead_provider) }

  before { allow(state_store).to receive(:ect_lead_provider).and_return(ect_lead_provider) }

  it { is_expected.to be_valid }

  describe "#lead_provider" do
    it "is the ECTs lead provider" do
      expect(step.lead_provider).to eq(ect_lead_provider)
    end
  end
end
