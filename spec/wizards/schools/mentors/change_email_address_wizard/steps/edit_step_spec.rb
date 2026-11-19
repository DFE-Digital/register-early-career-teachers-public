describe Schools::Mentors::ChangeEmailAddressWizard::Steps::EditStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeEmailAddressWizard::Wizard.new(
      current_step: :edit,
      current_step_params: { edit: params },
      state_store:
    )
  end
  let(:state_store) do
    Schools::Mentors::ChangeEmailAddressWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      author:,
      mentor_at_school_period:
    )
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:params) { { email: "email@example.com" } }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params).to contain_exactly(:email)
    end
  end

  describe "validations" do
    context "when email is blank" do
      let(:params) { { email: "" } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:email)).to contain_exactly(
          "Enter an email address"
        )
      end
    end

    context "when email is invalid" do
      let(:params) { { email: "invalid_email" } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:email)).to contain_exactly(
          "Enter an email address in the correct format, like name@example.com"
        )
      end
    end

    context "when email is too long" do
      let(:params) { { email: "a" * 250 + "@example.com" } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:email)).to contain_exactly(
          "Enter an email address that is less than 254 characters long"
        )
      end
    end

    context "when email hasn't been changed" do
      let(:params) { { email: mentor_at_school_period.email } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:email)).to contain_exactly(
          "The email must be different from the current email"
        )
      end
    end

    context "when email is valid" do
      let(:params) { { email: "new_email@example.com" } }

      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end
end
