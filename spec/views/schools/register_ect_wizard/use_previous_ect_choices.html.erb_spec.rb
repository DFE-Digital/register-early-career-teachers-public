require_relative './shared_examples/use_previous_ect_choices_view'

RSpec.describe "schools/register_ect_wizard/use_previous_ect_choices.html.erb" do
  it_behaves_like 'a use previous ect choices view',
                  current_step: :use_previous_ect_choices,
                  back_path: :schools_register_ect_wizard_working_pattern_path,
                  back_step_name: :working_pattern,
                  continue_path: :schools_register_ect_wizard_use_previous_ect_choices_path,
                  continue_step_name: :use_previous_ect_choices
end
