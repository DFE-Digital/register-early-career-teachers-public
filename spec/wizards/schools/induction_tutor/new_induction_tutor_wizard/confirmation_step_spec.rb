describe Schools::InductionTutor::NewInductionTutorWizard::ConfirmationStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::InductionTutor::NewInductionTutorWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(confirmation: params),
      author:,
      store:,
      school_id: school.id
    )
  end

  let(:store)  { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }

  let(:params) { {} }

  describe "#previous_step" do
    it "returns the previous step" do
      expect(current_step.previous_step).to eq(:check_answers)
    end
  end

  describe "#next_step" do
    it "raises an error" do
      expect { current_step.next_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#new_induction_teacher_name" do
    it "returns the school's induction tutor name" do
      expect(current_step.new_induction_teacher_name).to eq(school.induction_tutor_name)
    end
  end

  describe "#new_induction_teacher_email" do
    it "returns the school's induction tutor email" do
      expect(current_step.new_induction_teacher_email).to eq(school.induction_tutor_email)
    end
  end
end
