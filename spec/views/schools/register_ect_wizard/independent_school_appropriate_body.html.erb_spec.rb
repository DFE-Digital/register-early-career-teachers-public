require_relative './shared_examples/independent_school_appropriate_body_view'

RSpec.describe "schools/register_ect_wizard/independent_school_appropriate_body.html.erb" do
  it_behaves_like 'an independent school appropriate body view',
                  current_step: :independent_school_appropriate_body,
                  back_path: :schools_register_ect_wizard_working_pattern_path,
                  back_step_name: 'working pattern',
                  continue_path: :schools_register_ect_wizard_independent_school_appropriate_body_path,
                  continue_step_name: 'independent school appropriate body'
end
