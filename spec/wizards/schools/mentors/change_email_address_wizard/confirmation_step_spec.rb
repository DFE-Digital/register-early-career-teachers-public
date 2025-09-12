describe Schools::Mentors::ChangeEmailAddressWizard::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeEmailAddressWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(confirmation: params),
      author:,
      store:,
      mentor_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
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

  describe "#new_email" do
    it "returns the mentor's email" do
      expect(current_step.new_email).to eq(mentor_at_school_period.email)
    end
  end
end
