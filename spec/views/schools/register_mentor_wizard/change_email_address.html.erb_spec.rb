require_relative './shared_examples/email_view'

RSpec.describe "schools/register_mentor_wizard/change_email_address.html.erb" do
  it_behaves_like 'an email address step view',
                  current_step: :change_email_address,
                  back_path: :schools_register_mentor_wizard_check_answers_path,
                  back_step_name: 'check answers',
                  continue_path: :schools_register_mentor_wizard_change_email_address_path,
                  continue_step_name: 'change email address'
end
