require_relative './shared_examples/cant_use_email_step'

describe Schools::RegisterMentorWizard::CantUseEmailStep, type: :model do
  it_behaves_like "a can't use email step",
                  current_step: :cant_use_email,
                  previous_step: :email_address,
                  next_step: :email_address
end
