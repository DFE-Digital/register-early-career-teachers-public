RSpec.describe Schools::AssignExistingMentorWizard::Wizard do
  subject(:wizard) { described_class.new(state_store:, current_step:) }

  let(:state_store) { Schools::AssignExistingMentorWizard::StateStore.new }
  let(:current_step) { :review_mentor_eligibility }

  it { is_expected.to have_root_step(:review_mentor_eligibility) }

  it "defines a route for every step" do
    expect(described_class.routes).to match_array(wizard.step_definitions.keys)
  end

  it "resolves step paths" do
    expect(wizard).to resolve_step(:lead_provider).to("/school/assign-existing-mentor/lead-provider")
  end

  describe "operations" do
    it "assigns the mentor when their eligibility is reviewed" do
      expect(wizard).to have_step_operations(
        review_mentor_eligibility: [Schools::AssignExistingMentorWizard::Operations::AssignMentorWithTraining]
      )
    end

    it "assigns the mentor once a valid lead provider is stored" do
      expect(wizard).to have_step_operations(
        lead_provider: [
          DfE::Wizard::Operations::Validate,
          DfE::Wizard::Operations::Persist,
          Schools::AssignExistingMentorWizard::Operations::AssignMentorWithTraining
        ]
      )
    end
  end

  describe "navigation" do
    it { is_expected.to have_next_step(:confirmation).from(:review_mentor_eligibility) }
    it { is_expected.to have_next_step(:confirmation).from(:lead_provider) }
  end

  describe "#author" do
    let(:user) { FactoryBot.build_stubbed(:user) }

    before { allow(Current).to receive(:user).and_return(user) }

    it "is the current user" do
      expect(wizard.author).to eq(user)
    end
  end
end
