RSpec.describe Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Wizard do
  subject(:wizard) { described_class.new(state_store:, current_step:) }

  let(:state_store) { Schools::InductionTutor::StateStore.new(school:) }
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }
  let(:current_step) { :edit }

  it { is_expected.to have_root_step(:edit) }

  it "defines a route for every step" do
    expect(described_class.routes).to match_array(wizard.step_definitions.keys)
  end

  it "resolves step paths" do
    expect(wizard).to resolve_step(:check_answers).to("/school/induction-tutor/confirm-existing-induction-tutor/check-answers")
  end

  describe "operations" do
    it "confirms the induction tutor after storing the edit step" do
      expect(wizard).to have_step_operations(
        edit: [
          DfE::Wizard::Operations::Validate,
          DfE::Wizard::Operations::Persist,
          Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Operations::Confirm
        ]
      )
    end

    it "updates the induction tutor on the check answers step" do
      expect(wizard).to have_step_operations(
        check_answers: [Schools::InductionTutor::Operations::Update]
      )
    end
  end

  describe "navigation" do
    context "when the details are confirmed as correct" do
      before { state_store.write(are_these_details_correct: true) }

      it { is_expected.to have_next_step(:confirmation).from(:edit) }
    end

    context "when the details are not correct" do
      before { state_store.write(are_these_details_correct: false) }

      it { is_expected.to have_next_step(:check_answers).from(:edit) }
      it { is_expected.to have_next_step(:confirmation).from(:check_answers) }
    end
  end

  describe "#author" do
    let(:user) { FactoryBot.build_stubbed(:user) }

    before { allow(Current).to receive(:user).and_return(user) }

    it "is the current user" do
      expect(wizard.author).to eq(user)
    end
  end
end
