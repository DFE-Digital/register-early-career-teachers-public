RSpec.describe Schools::Mentors::ChangeNameWizard::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    FactoryBot.build(:change_mentor_name_wizard,
      current_step: :confirmation)
  end

  describe "#next_step" do
    it { expect { current_step.next_step }.to raise_error(NotImplementedError) }
  end

  describe "#previous_step" do
    it { expect { current_step.previous_step }.to raise_error(NotImplementedError) }
  end
end
