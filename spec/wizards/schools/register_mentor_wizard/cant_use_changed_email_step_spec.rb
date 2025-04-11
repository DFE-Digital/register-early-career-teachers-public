require_relative './shared_examples/cant_use_email_step'

describe Schools::RegisterMentorWizard::CantUseChangedEmailStep, type: :model do
  it_behaves_like "a can't use email step",
                  current_step: :cant_use_changed_email,
                  previous_step: :change_email_address,
                  next_step: :change_email_address
end
