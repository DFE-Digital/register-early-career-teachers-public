describe Schools::RegisterMentorWizard::EmailAddressStep, type: :model do
  subject { described_class.new }

  describe 'validations' do
    it { is_expected.to allow_value('valid@email.com').for(:email) }
    it { is_expected.not_to allow_value('invalid email').for(:email) }
  end

  describe '#next_step' do
    let(:wizard) do
      FactoryBot.build(:register_mentor_wizard, current_step: :email_address, step_params:)
    end

    let(:step_params) do
      ActionController::Parameters.new("email_address" => { "email" => 'valid@email.com' })
    end

    it { expect(wizard.next_step).to eq(:check_answers) }
  end
end
