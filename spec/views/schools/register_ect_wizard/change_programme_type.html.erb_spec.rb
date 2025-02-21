require_relative './shared_examples/programme_type_view'

RSpec.describe "schools/register_ect_wizard/change_programme_type.html.erb" do
  it_behaves_like "a programme type view",
                  current_step: :change_programme_type,
                  back_path: :schools_register_ect_wizard_check_answers_path,
                  back_step_name: 'check answers',
                  continue_path: :schools_register_ect_wizard_change_programme_type_path,
                  continue_step_name: 'change programme type'
end
