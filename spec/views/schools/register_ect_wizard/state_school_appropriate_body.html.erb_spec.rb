require_relative './shared_examples/state_school_appropriate_body_view'

RSpec.describe "schools/register_ect_wizard/state_school_appropriate_body.html.erb" do
  it_behaves_like "a state school appropriate body view",
                  current_step: :state_school_appropriate_body,
                  back_path: :schools_register_ect_wizard_working_pattern_path,
                  back_step_name: 'working pattern',
                  continue_path: :schools_register_ect_wizard_state_school_appropriate_body_path,
                  continue_step_name: 'state school appropriate body'
end
