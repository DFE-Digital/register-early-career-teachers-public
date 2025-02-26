require_relative './shared_examples/programme_type_view'

RSpec.describe "schools/register_ect_wizard/programme_type.html.erb" do
  it_behaves_like "a programme type view",
                  current_step: :programme_type,
                  back_path: :schools_register_ect_wizard_independent_school_appropriate_body_path,
                  back_step_name: 'independent school appropriate body',
                  continue_path: :schools_register_ect_wizard_programme_type_path,
                  continue_step_name: 'programme type'
end
