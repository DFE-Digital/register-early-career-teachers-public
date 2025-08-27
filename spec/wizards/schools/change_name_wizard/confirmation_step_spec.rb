RSpec.describe Schools::ChangeNameWizard::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    FactoryBot.build(:change_name_wizard,
                     current_step: :confirmation)
  end

  describe '#next_step' do
    it { expect { current_step.next_step }.to raise_error(NotImplementedError) }
  end

  describe '#previous_step' do
    it { expect(current_step.previous_step).to eq(:check_answers) }
  end
end
