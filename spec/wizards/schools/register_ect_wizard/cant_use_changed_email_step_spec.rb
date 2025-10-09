RSpec.describe Schools::RegisterECTWizard::CantUseChangedEmailStep do
  subject { described_class.new(wizard:) }

  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :cant_use_changed_email, store:) }

  describe '#next_step' do
    it 'returns change_email_address' do
      expect(subject.next_step).to eq(:change_email_address)
    end
  end

  describe '#previous_step' do
    it 'returns change_email_address' do
      expect(subject.previous_step).to eq(:change_email_address)
    end
  end
end
