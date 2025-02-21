require_relative './shared_examples/independent_school_appropriate_body_view'

RSpec.describe "schools/register_ect_wizard/change_independent_school_appropriate_body.html.erb" do
  it_behaves_like 'an independent school appropriate body view',
                  current_step: :change_independent_school_appropriate_body,
                  back_path: :schools_register_ect_wizard_check_answers_path,
                  back_step_name: 'check answers',
                  continue_path: :schools_register_ect_wizard_change_independent_school_appropriate_body_path,
                  continue_step_name: 'change independent school appropriate body'
end
