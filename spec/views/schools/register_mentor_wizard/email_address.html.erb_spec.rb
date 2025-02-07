require_relative './shared_examples/email_view'

RSpec.describe "schools/register_mentor_wizard/email_address.html.erb" do
  it_behaves_like 'an email address step view',
                  current_step: :email_address,
                  back_path: :schools_register_mentor_wizard_review_mentor_details_path,
                  back_step_name: 'review mentor details',
                  continue_path: :schools_register_mentor_wizard_email_address_path,
                  continue_step_name: 'email address'
end
