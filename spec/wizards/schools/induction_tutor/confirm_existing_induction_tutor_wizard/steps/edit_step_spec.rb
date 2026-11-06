RSpec.describe Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Steps::EditStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Wizard.new(
      state_store: Schools::InductionTutor::StateStore.new(school:),
      current_step: :edit,
      current_step_params: { edit: { are_these_details_correct:, induction_tutor_name:, induction_tutor_email: } }
    )
  end
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }
  let(:are_these_details_correct) { true }
  let(:induction_tutor_name) { school.induction_tutor_name }
  let(:induction_tutor_email) { school.induction_tutor_email }

  describe ".permitted_params" do
    it "returns the permitted params" do
      expect(described_class.permitted_params).to match_array(%i[are_these_details_correct induction_tutor_email induction_tutor_name])
    end
  end

  describe "validations" do
    context "when are_these_details_correct is not selected" do
      let(:are_these_details_correct) { nil }

      it { is_expected.to have_error(:are_these_details_correct, "Select 'Yes' or 'No, someone else will be the induction tutor'") }
    end

    context "when the user has confirmed the existing details are correct" do
      it { is_expected.to be_valid }

      context "when the name and email are blank" do
        let(:induction_tutor_name) { nil }
        let(:induction_tutor_email) { nil }

        it { is_expected.to be_valid }
      end
    end

    context "when the user needs to change the details" do
      let(:are_these_details_correct) { false }
      let(:induction_tutor_name) { "New Name" }
      let(:induction_tutor_email) { "new.name@example.com" }

      it { is_expected.to be_valid }

      context "when both attributes are unchanged" do
        let(:induction_tutor_name) { school.induction_tutor_name }
        let(:induction_tutor_email) { school.induction_tutor_email }

        it { is_expected.to have_error(:base, "You must change the induction tutor details or confirm they are correct") }
      end

      context "when induction_tutor_name is blank" do
        let(:induction_tutor_name) { nil }

        it { is_expected.to have_error(:induction_tutor_name, "Enter the correct full name") }
      end

      context "when induction_tutor_name is too long" do
        let(:induction_tutor_name) { "A" * 71 }

        it { is_expected.to have_error(:induction_tutor_name, "Full name must be 70 letters or less") }
      end

      context "when induction_tutor_email is blank" do
        let(:induction_tutor_email) { nil }

        it { is_expected.to have_error(:induction_tutor_email, "Enter an email address") }
      end

      context "when induction_tutor_email is invalid" do
        let(:induction_tutor_email) { "invalid_email" }

        it { is_expected.to have_error(:induction_tutor_email, "Enter an email address in the correct format, like name@example.com") }
      end

      context "when induction_tutor_email is too long" do
        let(:induction_tutor_email) { "#{'A' * 243}@example.com" }

        it { is_expected.to have_error(:induction_tutor_email, "Enter an email address that is less than 254 characters long") }
      end
    end
  end
end
