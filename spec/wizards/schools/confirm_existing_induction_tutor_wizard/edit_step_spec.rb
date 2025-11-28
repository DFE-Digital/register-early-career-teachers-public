describe Schools::ConfirmExistingInductionTutorWizard::EditStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ConfirmExistingInductionTutorWizard::Wizard.new(
      current_step: :edit,
      step_params: ActionController::Parameters.new(edit: params),
      author:,
      store:,
      school_id: school.id
    )
  end

  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }

  let(:induction_tutor_email) { school.induction_tutor_email }
  let(:induction_tutor_name) { school.induction_tutor_name }
  let(:are_these_details_correct) { true }

  let(:params) { { induction_tutor_email:, induction_tutor_name:, are_these_details_correct: } }

  describe ".permitted_params" do
    it "returns the permitted params" do
      expect(described_class.permitted_params).to match_array(%i[induction_tutor_email induction_tutor_name school_id are_these_details_correct])
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#next_step" do
    context "when the user has confirmed the details are correct" do
      it "returns :confirmation" do
        expect(current_step.next_step).to eq(:confirmation)
      end
    end

    context "when the user has changed the details" do
      let(:are_these_details_correct) { false }

      it "returns :check_answers" do
        expect(current_step.next_step).to eq(:check_answers)
      end
    end
  end

  describe "validations" do
    context "when are_these_details_correct is not selected" do
      let(:are_these_details_correct) { nil }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:are_these_details_correct)).to contain_exactly(
          "Select 'Yes' if these details are correct"
        )
      end
    end

    context "when the user needs to change the details" do
      let(:are_these_details_correct) { false }

      context "when induction_tutor_email is blank" do
        let(:induction_tutor_email) { nil }

        it "is invalid" do
          expect(current_step).not_to be_valid
          expect(current_step.errors.messages_for(:induction_tutor_email)).to contain_exactly(
            "Email cannot be blank"
          )
        end
      end

      context "when induction_tutor_name is blank" do
        let(:induction_tutor_name) { nil }

        it "is invalid" do
          expect(current_step).not_to be_valid
          expect(current_step.errors.messages_for(:induction_tutor_name)).to contain_exactly(
            "Name cannot be blank"
          )
        end
      end

      context "when the email has changed" do
        let(:induction_tutor_email) { Faker::Internet.email }

        it "is valid" do
          expect(current_step).to be_valid
          expect(current_step.errors).to be_empty
        end
      end

      context "when the name has changed" do
        let(:induction_tutor_name) { "New Name" }

        it "is valid" do
          expect(current_step).to be_valid
          expect(current_step.errors).to be_empty
        end
      end

      context "when both attributes are unchanged" do
        it "is not valid" do
          expect(current_step).not_to be_valid
          expect(current_step.errors.messages_for(:base)).to contain_exactly(
            "You must change the induction tutor details or confirm they are correct"
          )
        end
      end
    end

    context "when the user has confirmed the existing details are correct" do
      let(:are_these_details_correct) { true }

      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end
end
