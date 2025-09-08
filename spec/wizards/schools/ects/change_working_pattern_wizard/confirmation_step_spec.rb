describe Schools::ECTs::ChangeWorkingPatternWizard::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeWorkingPatternWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(confirmation: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
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

  describe "#new_working_pattern" do
    it "returns the ECT's working pattern" do
      expect(current_step.new_working_pattern).to eq(ect_at_school_period.working_pattern)
    end
  end
end
