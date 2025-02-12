require_relative './shared_examples/review_mentor_details_step'

describe Schools::RegisterMentorWizard::ReviewMentorDetailsStep, type: :model do
  it_behaves_like 'a review mentor details step',
                  current_step: :review_mentor_details,
                  next_step: :email_address
end
