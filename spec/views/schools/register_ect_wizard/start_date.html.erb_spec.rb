require_relative './shared_examples/start_date_view'

RSpec.describe "schools/register_ect_wizard/start_date.html.erb" do
  it_behaves_like "a start date view",
                  current_step: :start_date,
                  back_path: :schools_register_ect_wizard_email_address_path,
                  back_step_name: 'email address',
                  continue_path: :schools_register_ect_wizard_start_date_path,
                  continue_step_name: 'start date'
end
