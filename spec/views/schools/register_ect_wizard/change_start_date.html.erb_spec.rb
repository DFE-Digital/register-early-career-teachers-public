require_relative './shared_examples/start_date_view'

RSpec.describe "schools/register_ect_wizard/change_start_date.html.erb" do
  it_behaves_like "a start date view",
                  current_step: :change_start_date,
                  back_path: :schools_register_ect_wizard_check_answers_path,
                  back_step_name: 'check answers',
                  continue_path: :schools_register_ect_wizard_change_start_date_path,
                  continue_step_name: 'change start date'
end
