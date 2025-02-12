require_relative './shared_examples/review_mentor_details_step'

describe Schools::RegisterMentorWizard::ChangeMentorDetailsStep, type: :model do
  it_behaves_like 'a review mentor details step',
                  current_step: :change_mentor_details,
                  next_step: :check_answers
end
