require_relative './shared_examples/email_step'

describe Schools::RegisterMentorWizard::EmailAddressStep, type: :model do
  it_behaves_like 'an email step', current_step: :email_address, previous_step: :review_mentor_details
end
