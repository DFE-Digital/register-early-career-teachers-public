RSpec.describe Schools::InductionTutor::UpdateInductionTutorWizard::Steps::EditStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Schools::InductionTutor::UpdateInductionTutorWizard::Wizard.new(
      state_store: Schools::InductionTutor::StateStore.new(school:),
      current_step: :edit,
      current_step_params: { edit: { induction_tutor_name:, induction_tutor_email: } }
    )
  end
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }
  let(:induction_tutor_name) { "New Name" }
  let(:induction_tutor_email) { "new.name@example.com" }

  it { is_expected.to be_a(Schools::InductionTutor::Steps::EditStep) }

  describe "validations" do
    context "when the details have changed" do
      it { is_expected.to be_valid }
    end

    context "when only the name has changed" do
      let(:induction_tutor_email) { school.induction_tutor_email }

      it { is_expected.to be_valid }
    end

    context "when neither the name nor email have changed" do
      let(:induction_tutor_name) { school.induction_tutor_name }
      let(:induction_tutor_email) { school.induction_tutor_email }

      it { is_expected.to have_error(:base, "You must change one of the fields to change the induction tutor details") }
    end
  end
end
