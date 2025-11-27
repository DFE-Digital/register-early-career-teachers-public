describe Schools::Induction::ConfirmExistingInductionTutorWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Induction::ConfirmExistingInductionTutorWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      school:
    )
  end

  let(:store)  { FactoryBot.build(:session_repository, induction_tutor_email:, induction_tutor_name:) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }

  let(:induction_tutor_email) { Faker::Internet.email }
  let(:induction_tutor_name) { Faker::Name.name }

  let(:params) { {} }

  describe "#previous_step" do
    it "returns the previous step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the next step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#save!" do
    it "updates the school's induction tutor details" do
      expect { current_step.save! }
        .to change(school, :induction_tutor_email)
        .to(induction_tutor_email)
        .and change(school, :induction_tutor_name)
        .to(induction_tutor_name)
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end

    xit "records an event" do
    end
  end
end
