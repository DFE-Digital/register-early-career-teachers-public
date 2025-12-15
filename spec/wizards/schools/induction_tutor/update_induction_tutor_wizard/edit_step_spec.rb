describe Schools::InductionTutor::UpdateInductionTutorWizard::EditStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::InductionTutor::UpdateInductionTutorWizard::Wizard.new(
      current_step: :edit,
      step_params: ActionController::Parameters.new(edit: params),
      author:,
      store:,
      school_id: school.id
    )
  end

  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }

  let(:induction_tutor_email) { "new.email@example.com" }
  let(:induction_tutor_name) { "New Name" }

  let(:params) { { induction_tutor_email:, induction_tutor_name: } }

  let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }

  describe ".permitted_params" do
    it "returns the permitted params" do
      expect(described_class.permitted_params).to match_array(%i[induction_tutor_email induction_tutor_name])
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#next_step" do
    context "when the user has confirmed the details are correct" do
      it "returns :check_answers" do
        expect(current_step.next_step).to eq(:check_answers)
      end
    end
  end

  describe "validations" do
    context "when induction_tutor_email is blank" do
      let(:induction_tutor_email) { nil }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:induction_tutor_email)).to contain_exactly(
          "Enter an email address"
        )
      end
    end

    context "when email is invalid" do
      let(:induction_tutor_email) { "invalid_email" }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:induction_tutor_email)).to contain_exactly(
          "Enter an email address in the correct format, like name@example.com"
        )
      end
    end

    context "when induction_tutor_email is too long" do
      let(:induction_tutor_email) { "A" * 243 + "@example.com" }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:induction_tutor_email)).to contain_exactly(
          "Enter an email address that is less than 254 characters long"
        )
      end
    end

    context "when the email is valid" do
      let(:induction_tutor_email) { Faker::Internet.email }

      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end

    context "when induction_tutor_name is blank" do
      let(:induction_tutor_name) { nil }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:induction_tutor_name)).to contain_exactly(
          "Enter the correct full name"
        )
      end
    end

    context "when induction_tutor_name is too long" do
      let(:induction_tutor_name) { "A" * 71 }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:induction_tutor_name)).to contain_exactly(
          "Full name must be 70 letters or less"
        )
      end
    end

    context "when the name and email are valid" do
      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end

  describe "#save!" do
    context "when the step is valid" do
      it "stores the data" do
        expect { current_step.save! }.to change(store, :induction_tutor_name).to("New Name")
        .and change(store, :induction_tutor_email).to("new.email@example.com")
      end
    end

    context "when the step is invalid" do
      let(:induction_tutor_name) { nil }
      let(:induction_tutor_email) { "invalid_email" }

      it "does not store any data" do
        expect { current_step.save! }.not_to change(store, :attributes)
      end
    end
  end
end
