require_relative './shared_examples/state_school_appropriate_body_view'

RSpec.describe "schools/register_ect_wizard/change_state_school_appropriate_body.html.erb" do
  it_behaves_like "a state school appropriate body view",
                  current_step: :change_state_school_appropriate_body,
                  back_path: :schools_register_ect_wizard_check_answers_path,
                  back_step_name: 'check answers',
                  continue_path: :schools_register_ect_wizard_change_state_school_appropriate_body_path,
                  continue_step_name: 'change state school appropriate body'
end
