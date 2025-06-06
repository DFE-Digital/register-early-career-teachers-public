require_relative './shared_examples/training_programme_view'

RSpec.describe "schools/register_ect_wizard/training_programme.html.erb" do
  it_behaves_like "a programme type view",
                  current_step: :training_programme,
                  back_path: :schools_register_ect_wizard_independent_school_appropriate_body_path,
                  back_step_name: 'independent school appropriate body',
                  continue_path: :schools_register_ect_wizard_training_programme_path,
                  continue_step_name: 'programme type'
end
