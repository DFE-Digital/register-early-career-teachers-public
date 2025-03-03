require_relative './shared_examples/use_previous_ect_choices_view'

RSpec.describe "schools/register_ect_wizard/change_use_previous_ect_choices.html.erb" do
  it_behaves_like 'a use previous ect choices view',
                  current_step: :change_use_previous_ect_choices,
                  back_path: :schools_register_ect_wizard_check_answers_path,
                  back_step_name: :check_answers,
                  continue_path: :schools_register_ect_wizard_change_use_previous_ect_choices_path,
                  continue_step_name: :change_use_previous_ect_choices
end
