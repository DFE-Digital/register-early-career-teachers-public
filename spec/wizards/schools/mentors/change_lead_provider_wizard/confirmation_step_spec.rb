describe Schools::Mentors::ChangeLeadProviderWizard::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeLeadProviderWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(confirmation: params),
      author:,
      store:,
      mentor_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
  let(:lead_provider) { school_partnership.lead_provider }
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

  xdescribe "#new_lead_provider" do
    it "returns the mentor's lead provider" do
      expect(current_step.new_lead_provider).to eq(lead_provider)
    end
  end
end
