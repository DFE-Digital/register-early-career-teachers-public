require_relative './shared_examples/email_step'

describe Schools::RegisterMentorWizard::ChangeEmailAddressStep, type: :model do
  it_behaves_like 'an email step', current_step: :change_email_address
end
