require_relative './shared_examples/review_mentor_details_view'

RSpec.describe "schools/register_mentor_wizard/change_mentor_details.html.erb" do
  it_behaves_like 'a review mentor details step view',
                  current_step: :change_mentor_details,
                  back_path: :schools_register_mentor_wizard_check_answers_path,
                  back_step_name: 'check answers',
                  confirm_and_continue_path: :schools_register_mentor_wizard_change_mentor_details_path,
                  continue_step_name: 'change mentor details',
                  check_details_path: :schools_register_mentor_wizard_find_mentor_path,
                  check_details_step_name: 'find mentor'
end
