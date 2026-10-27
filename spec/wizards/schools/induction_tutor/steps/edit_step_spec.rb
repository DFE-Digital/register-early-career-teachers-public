RSpec.describe Schools::InductionTutor::Steps::EditStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Schools::InductionTutor::NewInductionTutorWizard::Wizard.new(
      state_store: Schools::InductionTutor::StateStore.new(school:),
      current_step: :edit,
      current_step_params: { edit: { induction_tutor_name:, induction_tutor_email: } }
    )
  end
  let(:school) { FactoryBot.create(:school, :without_induction_tutor) }
  let(:induction_tutor_name) { "New Name" }
  let(:induction_tutor_email) { "new.name@example.com" }

  describe ".permitted_params" do
    it "returns the permitted params" do
      expect(described_class.permitted_params).to match_array(%i[induction_tutor_email induction_tutor_name])
    end
  end

  describe "validations" do
    context "when the name and email are valid" do
      it { is_expected.to be_valid }
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
