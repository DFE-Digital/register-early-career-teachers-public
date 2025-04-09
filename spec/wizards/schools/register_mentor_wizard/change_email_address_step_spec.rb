require_relative './shared_examples/email_step'

describe Schools::RegisterMentorWizard::ChangeEmailAddressStep, type: :model do
  context 'when email is in use' do
    before do
      allow(wizard.mentor).to receive(:cant_use_email?).and_return(true)
    end

    it_behaves_like 'an email step',
                    current_step: :change_email_address,
                    previous_step: :check_answers,
                    next_step: :cant_use_changed_email
  end

  context 'when email is not in use' do
    it_behaves_like 'an email step',
                    current_step: :change_email_address,
                    previous_step: :check_answers,
                    next_step: :check_answers
  end
end
